import { createBinding, createComputed, createEffect, createState, onCleanup } from "ags"
import { Gtk } from "ags/gtk4"
import AstalNetwork from "gi://AstalNetwork"
import Button from "../../primitives/Button.tsx"
import { substituteTokens } from "../shared/template.ts"
import { useWidgetCommands } from "../shared/useWidgetCommands.ts"
import { mergeConfig, type WidgetClicks, type WidgetProps } from "../shared/types.ts"

type WifiIcons = [string, string, string, string, string]

type NetworkIcons = { disconnected: string; ethernet: string; wifi: WifiIcons }

// Empty strings disable the corresponding tooltip state.
type NetworkTooltip = {
  disconnected: string
  ethernet: string
  wifi: string
  wifiNoFreq: string
  wifiNoSsid: string
}

export type NetworkConfig = {
  commands?: WidgetClicks
  icons?: Partial<NetworkIcons>
  tooltip?: Partial<NetworkTooltip>
}

type NetworkDefaults = {
  commands: WidgetClicks
  icons: NetworkIcons
  tooltip: NetworkTooltip
}

export const defaults: NetworkDefaults = {
  commands: { primary: "hk-launch-wifi" },
  icons: {
    disconnected: "󰤮",
    ethernet: "󰀂",
    wifi: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"],
  },
  tooltip: {
    disconnected: "Disconnected",
    ethernet: "Ethernet connected",
    wifi: "{ssid} ({freq} GHz)",
    wifiNoFreq: "{ssid}",
    wifiNoSsid: "Wi-Fi connected",
  },
}

function readString(value: unknown): string {
  return typeof value === "string" ? value.trim() : ""
}

function selectWifiIcon(strength: number, wifiIcons: WifiIcons) {
  if (strength >= 80) return wifiIcons[4]
  if (strength >= 60) return wifiIcons[3]
  if (strength >= 40) return wifiIcons[2]
  if (strength >= 20) return wifiIcons[1]
  return wifiIcons[0]
}

function formatWifiTooltip(ssid: string, frequency: number, tooltip: NetworkTooltip): string {
  if (ssid.length === 0) return tooltip.wifiNoSsid
  if (frequency > 0) return substituteTokens(tooltip.wifi, { ssid, freq: (frequency / 1000).toFixed(1) })
  return substituteTokens(tooltip.wifiNoFreq, { ssid })
}

export default function NetworkWidget({ config, placement }: WidgetProps<NetworkConfig>) {
  const cfg = mergeConfig(defaults, config)
  const { commands, icons, tooltip } = cfg
  const isVertical = placement.orientation === "vertical"
  const network = AstalNetwork.get_default()

  const tooltipEnabled = Boolean(
    tooltip.disconnected || tooltip.ethernet || tooltip.wifi || tooltip.wifiNoFreq || tooltip.wifiNoSsid,
  )

  const primary = createBinding(network, "primary")
  const networkState = createBinding(network, "state")
  const wifiRef = createBinding(network, "wifi")
  const wiredRef = createBinding(network, "wired")

  const [wifiStrength, setWifiStrength] = createState(0)
  const [wifiSsid, setWifiSsid] = createState("")
  const [wifiFrequency, setWifiFrequency] = createState(0)

  let wifiConns: { obj: AstalNetwork.Wifi; ids: number[] } | null = null

  function clearWifiConns() {
    if (wifiConns) {
      wifiConns.ids.forEach((id) => wifiConns!.obj.disconnect(id))
      wifiConns = null
    }
  }

  createEffect(() => {
    clearWifiConns()
    const wifi = wifiRef()
    if (!wifi) {
      setWifiStrength(0)
      setWifiSsid("")
      setWifiFrequency(0)
      return
    }
    setWifiStrength(wifi.strength)
    setWifiSsid(wifi.ssid)
    setWifiFrequency(wifi.frequency)
    const ids = [
      wifi.connect("notify::strength", () => setWifiStrength(wifi.strength)),
      wifi.connect("notify::ssid", () => setWifiSsid(wifi.ssid)),
      wifi.connect("notify::frequency", () => setWifiFrequency(wifi.frequency)),
    ]
    wifiConns = { obj: wifi, ids }
  })

  onCleanup(clearWifiConns)

  const icon = createComputed(() => {
    const p = primary()
    const s = networkState()
    const connected = typeof s === "number" && s >= AstalNetwork.State.CONNECTED_LOCAL

    if (!connected) return icons.disconnected
    if (p === AstalNetwork.Primary.WIRED) return icons.ethernet
    if (p === AstalNetwork.Primary.WIFI) return selectWifiIcon(wifiStrength(), icons.wifi)

    const wiredIconName = readString(wiredRef()?.iconName)
    if (wiredIconName.length > 0 && wiredIconName !== "network-wired-disconnected-symbolic") {
      return icons.ethernet
    }
    return icons.disconnected
  })

  const tooltipText = createComputed(() => {
    const p = primary()
    const s = networkState()
    const connected = typeof s === "number" && s >= AstalNetwork.State.CONNECTED_LOCAL

    if (!connected) return tooltip.disconnected
    if (p === AstalNetwork.Primary.WIRED) return tooltip.ethernet
    if (p === AstalNetwork.Primary.WIFI) return formatWifiTooltip(wifiSsid(), wifiFrequency(), tooltip)

    const wiredIconName = readString(wiredRef()?.iconName)
    if (wiredIconName.length > 0 && wiredIconName !== "network-wired-disconnected-symbolic") {
      return tooltip.ethernet
    }
    return tooltip.disconnected
  })

  const { execPrimary, execSecondary, execTertiary } = useWidgetCommands({ commands })

  return (
    <Button
      class="widget-network-button widget-glyph-button"
      orientation={placement.orientation}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execTertiary={execTertiary}
      tooltipText={tooltipEnabled ? tooltipText : undefined}
    >
      <box
        class="widget-network-content"
        hexpand={isVertical}
        halign={Gtk.Align.CENTER}
      >
        <label class="widget-network-glyph" xalign={0.5} label={icon} />
      </box>
    </Button>
  )
}
