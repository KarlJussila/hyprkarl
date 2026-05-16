import { createEffect } from "ags"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"
import { Gtk } from "ags/gtk4"
import AstalNetwork from "gi://AstalNetwork"
import { type BarOrientation } from "../../layout/placement.ts"
import Button from "../../primitives/Button.tsx"

type Props = {
  orientation: BarOrientation
  command: string
}

type NetworkSnapshot = {
  icon: string
  tooltip: string
}

const wifiIcons = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
const ethernetIcon = "󰀂"
const disconnectedIcon = "󰤮"

function readString(value: unknown) {
  return typeof value === "string" ? value : ""
}

function readNumber(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : 0
}

function formatWifiTooltip(wifi: any) {
  const ssid = readString(wifi?.ssid).trim()
  const frequency = readNumber(wifi?.frequency)
  if (ssid.length === 0) {
    return "Wi-Fi connected"
  }

  if (frequency > 0) {
    return `${ssid} (${(frequency / 1000).toFixed(1)} GHz)`
  }

  return ssid
}

function selectWifiIcon(strength: number) {
  if (strength >= 80) return wifiIcons[4]
  if (strength >= 60) return wifiIcons[3]
  if (strength >= 40) return wifiIcons[2]
  if (strength >= 20) return wifiIcons[1]
  return wifiIcons[0]
}

function snapshotNetworkState(network: any): NetworkSnapshot {
  const primary = network?.primary
  const wifi = network?.wifi
  const wired = network?.wired
  const primaryWifi = primary === AstalNetwork.Primary.WIFI
  const primaryWired = primary === AstalNetwork.Primary.WIRED
  const state = network?.state
  const connected = typeof state === "number" && state >= AstalNetwork.State.CONNECTED_LOCAL

  if (primaryWired && connected) {
    return {
      icon: ethernetIcon,
      tooltip: "Ethernet connected",
    }
  }

  if (primaryWifi && connected) {
    return {
      icon: selectWifiIcon(readNumber(wifi?.strength)),
      tooltip: formatWifiTooltip(wifi),
    }
  }

  if (readString(wired?.iconName).length > 0 && readString(wired?.iconName) !== "network-wired-disconnected-symbolic") {
    return {
      icon: ethernetIcon,
      tooltip: "Ethernet connected",
    }
  }

  return {
    icon: disconnectedIcon,
    tooltip: "Disconnected",
  }
}

export default function NetworkWidget({ orientation, command }: Props) {
  const isVertical = orientation === "vertical"
  const network = AstalNetwork.get_default()
  const state = createPoll(
    snapshotNetworkState(network),
    2000,
    () => snapshotNetworkState(network),
  )

  return (
    <Button
      class="widget-network-button"
      hexpand={isVertical}
      halign={isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      execPrimary={() => execAsync(command).catch(() => {})}
      $={(button) => {
        createEffect(() => {
          button.set_tooltip_text(state().tooltip)
        })
      }}
    >
      <box
        class="widget-network-content"
        hexpand={isVertical}
        halign={Gtk.Align.CENTER}
      >
        <label class="widget-network-glyph" xalign={0.5} label={state((current) => current.icon)} />
      </box>
    </Button>
  )
}
