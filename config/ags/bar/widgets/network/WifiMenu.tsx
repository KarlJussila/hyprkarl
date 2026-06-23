import { Accessor, createBinding, createComputed, createState, For, With } from "ags"
import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { timeout, type Timer } from "ags/time"
import AstalNetwork from "gi://AstalNetwork"
import Button from "../../primitives/Button.tsx"
import { selectWifiIcon, type WifiIcons } from "./icons.ts"

type Props = {
  network: AstalNetwork.Network
  wifiIcons: WifiIcons
  lockedIcon: string
}

// NM.DeviceStateReason.NO_SECRETS — a wrong/missing Wi-Fi password. (@girs/nm
// isn't installed, so the numeric value stands in.)
const REASON_NO_SECRETS = 7

// One row per SSID (dedupe the per-band/radio APs to the strongest), active
// network pinned first and the rest sorted by signal strength.
function orderBySsid(aps: Array<AstalNetwork.AccessPoint>, activeSsid: string) {
  const best = new Map<string, AstalNetwork.AccessPoint>()
  for (const ap of aps) {
    if (!ap.ssid) continue
    const current = best.get(ap.ssid)
    if (!current || ap.strength > current.strength) best.set(ap.ssid, ap)
  }
  return [...best.values()].sort((a, b) => {
    if (a.ssid === activeSsid) return -1
    if (b.ssid === activeSsid) return 1
    return b.strength - a.strength
  })
}

// SSIDs we have saved NM profiles for. Uses nmcli rather than
// AccessPoint.get_connections() (marshalling its GPtrArray across the GJS
// boundary segfaults when the AP list churns). Keys off each profile's actual
// 802-11-wireless.ssid, not its name — NM names duplicate profiles "Foo 1".
const SAVED_SSIDS_CMD = [
  "bash",
  "-c",
  "nmcli -t -f UUID,TYPE connection show" +
    " | awk -F: '$2 ~ /wireless/{print $1}'" +
    " | while read -r u; do nmcli -t -g 802-11-wireless.ssid connection show \"$u\"; done",
]

// Deletes every saved wifi profile whose actual 802-11-wireless.ssid equals $1
// (matching the real SSID also catches NM's "Foo 1" duplicates). Used to scrub a
// profile after its password is rejected. (No ${} interpolation — every $ is shell.)
const FORGET_SSID_SCRIPT =
  `nmcli -t -f UUID,TYPE connection show | awk -F: '$2 ~ /wireless/ {print $1}'` +
  ` | while read -r uuid; do` +
  ` [ "$(nmcli -t -g 802-11-wireless.ssid connection show "$uuid")" = "$1" ]` +
  ` && nmcli connection delete uuid "$uuid" >/dev/null; done; true`

function parseSavedWifiSsids(ssidLines: string): Set<string> {
  const ssids = new Set<string>()
  for (const line of ssidLines.split("\n")) {
    const ssid = line.replace(/\\(.)/g, "$1") // un-escape nmcli's \: and \\
    if (ssid) ssids.add(ssid)
  }
  return ssids
}

type RowProps = {
  ap: AstalNetwork.AccessPoint
  activeSsid: Accessor<string>
  savedSsids: Accessor<ReadonlySet<string>>
  busy: Accessor<string | null>
  promptFor: Accessor<string | null>
  errorFor: Accessor<string | null>
  wifiIcons: WifiIcons
  lockedIcon: string
  onRowClick: (ap: AstalNetwork.AccessPoint) => void
  onSubmitPassword: (ap: AstalNetwork.AccessPoint, password: string) => void
}

function AccessPointRow({
  ap,
  activeSsid,
  savedSsids,
  busy,
  promptFor,
  errorFor,
  wifiIcons,
  lockedIcon,
  onRowClick,
  onSubmitPassword,
}: RowProps) {
  const isActive = activeSsid((ssid) => ssid === ap.ssid)
  const strengthGlyph = createBinding(ap, "strength")((s) => selectWifiIcon(s, wifiIcons))
  // Lock only flags networks that would actually prompt: secured, no stored
  // password, and not the currently-connected one.
  const lockVisible = createComputed(
    () =>
      Boolean(lockedIcon) &&
      ap.requiresPassword &&
      activeSsid() !== ap.ssid &&
      !savedSsids().has(ap.ssid ?? ""),
  )

  return (
    <box orientation={Gtk.Orientation.VERTICAL} hexpand>
      <Button
        class={isActive((active) => (active ? "flyout-row active" : "flyout-row"))}
        hexpand
        halign={Gtk.Align.FILL}
        execPrimary={() => onRowClick(ap)}
      >
        <box spacing={8} hexpand halign={Gtk.Align.FILL}>
          <label class="flyout-row-glyph" label={strengthGlyph} />
          <label hexpand xalign={0} label={ap.ssid ?? ""} />
          <label class="flyout-row-lock" label={lockedIcon} visible={lockVisible} />
          <label
            class="flyout-row-status"
            halign={Gtk.Align.END}
            visible={busy((b) => b === ap.ssid)}
            label="…"
          />
          <image
            halign={Gtk.Align.END}
            class="flyout-row-check"
            iconName="object-select-symbolic"
            visible={isActive}
          />
        </box>
      </Button>
      <revealer
        transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
        revealChild={promptFor((s) => s === ap.ssid)}
      >
        <entry
          class={errorFor((s) =>
            s === ap.ssid ? "flyout-password-entry error" : "flyout-password-entry",
          )}
          placeholderText="Password"
          visibility={false}
          onMap={(self) => self.grab_focus()}
          onActivate={(self) => onSubmitPassword(ap, self.text)}
        />
      </revealer>
    </box>
  )
}

function WifiList({ wifi, wifiIcons, lockedIcon }: { wifi: AstalNetwork.Wifi } & Pick<Props, "wifiIcons" | "lockedIcon">) {
  const activeSsid = createBinding(wifi, "activeAccessPoint")((ap) => ap?.ssid ?? "")
  const accessPointsRaw = createBinding(wifi, "accessPoints")
  const accessPoints = createComputed(() => orderBySsid(accessPointsRaw(), activeSsid()))
  // Transient per-row state is keyed by SSID, not BSSID: rows are deduped to the
  // strongest AP per SSID, so a rescan can swap the displayed BSSID for a network
  // mid-interaction — keying by SSID keeps the prompt/spinner attached to the row.
  const [busy, setBusy] = createState<string | null>(null)
  const [promptFor, setPromptFor] = createState<string | null>(null)
  const [errorFor, setErrorFor] = createState<string | null>(null)
  const [savedSsids, setSavedSsids] = createState<ReadonlySet<string>>(new Set())

  // Re-scan and re-read saved profiles each time the flyout opens (onMap fires
  // then). Nothing polls while it's closed.
  function refresh() {
    wifi.scan()
    execAsync(SAVED_SSIDS_CMD)
      .then((out) => setSavedSsids(parseSavedWifiSsids(out)))
      .catch((err) => console.error("failed to read saved wifi profiles", err))
  }

  function needsPassword(ap: AstalNetwork.AccessPoint) {
    return ap.requiresPassword && !savedSsids().has(ap.ssid ?? "")
  }

  // Scrub the rejected profile (so the lock returns), then prompt. Opening only
  // after the delete resolves stops a retry racing it into a duplicate profile.
  function forgetAndPrompt(ap: AstalNetwork.AccessPoint) {
    setSavedSsids(new Set([...savedSsids()].filter((s) => s !== ap.ssid)))
    const openPrompt = () => {
      setErrorFor(ap.ssid)
      setPromptFor(ap.ssid)
    }
    execAsync(["bash", "-c", FORGET_SSID_SCRIPT, "wifi-forget", ap.ssid ?? ""])
      .then(openPrompt)
      .catch((err) => {
        console.error("failed to forget wifi profile", err)
        openPrompt()
      })
  }

  function settleConnect(ap: AstalNetwork.AccessPoint, ok: boolean, reason: number) {
    // Only clear the spinner if it still belongs to this attempt — a stale
    // watcher must not wipe a newer connect's "…".
    if (busy() === ap.ssid) setBusy(null)
    if (ok) {
      setErrorFor(null)
      setPromptFor(null)
      // A successful connect leaves a saved profile, so drop the lock for it.
      setSavedSsids(new Set([...savedSsids(), ap.ssid ?? ""]))
      return
    }
    // A rejected password (NO_SECRETS) leaves a bad profile behind: forget it and
    // re-prompt. Other failures (out of range, etc.) just clear the spinner.
    if (reason === REASON_NO_SECRETS) forgetAndPrompt(ap)
  }

  // Success must key off the device reaching ACTIVATED (the AP flashes active
  // during ACTIVATING) AND the active AP being ours. The two updates can land in
  // either order, so watch both and confirm when both hold.
  function watchConnection(ap: AstalNetwork.AccessPoint) {
    let settled = false
    let activated = false
    let timer: Timer | undefined
    let stateId = 0
    let apId = 0
    const finish = (ok: boolean, reason: number) => {
      if (settled) return
      settled = true
      timer?.cancel()
      if (stateId) wifi.disconnect(stateId)
      if (apId) wifi.disconnect(apId)
      settleConnect(ap, ok, reason)
    }
    const confirmIfReady = () => {
      if (activated && wifi.activeAccessPoint?.ssid === ap.ssid) finish(true, 0)
    }
    stateId = wifi.connect(
      "state-changed",
      (_: AstalNetwork.Wifi, newState: number, _old: number, reason: number) => {
        if (newState === AstalNetwork.DeviceState.ACTIVATED) {
          activated = true
          confirmIfReady()
        } else if (newState === AstalNetwork.DeviceState.FAILED) {
          finish(false, reason)
        }
      },
    )
    apId = wifi.connect("notify::active-access-point", confirmIfReady)
    timer = timeout(20000, () => finish(false, 0))
  }

  function activate(ap: AstalNetwork.AccessPoint, password: string | null) {
    setErrorFor(null)
    setBusy(ap.ssid)
    ap.activate(password, (_, res) => {
      try {
        ap.activate_finish(res)
      } catch (err) {
        console.error("wifi connect failed", err)
        settleConnect(ap, false, 0)
        return
      }
      watchConnection(ap)
    })
  }

  function onRowClick(ap: AstalNetwork.AccessPoint) {
    // A second click on an open prompt cancels it.
    if (promptFor() === ap.ssid) {
      setPromptFor(null)
      setErrorFor(null)
      return
    }
    if (activeSsid() === ap.ssid) return
    // Only secured networks with no stored password need one; everything else
    // (open, or already-saved) connects directly.
    if (needsPassword(ap)) {
      setErrorFor(null)
      setPromptFor(ap.ssid)
      return
    }
    activate(ap, null)
  }

  function onSubmitPassword(ap: AstalNetwork.AccessPoint, password: string) {
    if (!password) return
    // Close the entry; the row shows "…" while connecting and the entry slides
    // back open (red) only on failure.
    setPromptFor(null)
    activate(ap, password)
  }

  return (
    <box orientation={Gtk.Orientation.VERTICAL} hexpand onMap={refresh}>
      <For each={accessPoints}>
        {(ap: AstalNetwork.AccessPoint) => (
          <AccessPointRow
            ap={ap}
            activeSsid={activeSsid}
            savedSsids={savedSsids}
            busy={busy}
            promptFor={promptFor}
            errorFor={errorFor}
            wifiIcons={wifiIcons}
            lockedIcon={lockedIcon}
            onRowClick={onRowClick}
            onSubmitPassword={onSubmitPassword}
          />
        )}
      </For>
      <label
        class="flyout-empty"
        xalign={0}
        label="No networks found"
        visible={accessPoints((list) => list.length === 0)}
      />
    </box>
  )
}

export default function WifiMenu({ network, wifiIcons, lockedIcon }: Props) {
  const wifi = createBinding(network, "wifi")

  return (
    <box orientation={Gtk.Orientation.VERTICAL} hexpand>
      <With value={wifi}>
        {(w: AstalNetwork.Wifi | null) =>
          w
            ? <WifiList wifi={w} wifiIcons={wifiIcons} lockedIcon={lockedIcon} />
            : <label class="flyout-empty" xalign={0} label="Wi-Fi unavailable" />
        }
      </With>
    </box>
  )
}
