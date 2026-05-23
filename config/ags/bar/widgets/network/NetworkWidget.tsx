import { createBinding, createComputed, createEffect, createState, onCleanup } from "ags"
import { execAsync } from "ags/process"
import { Gtk } from "ags/gtk4"
import AstalNetwork from "gi://AstalNetwork"
import { type BarOrientation } from "../../layout/placement.ts"
import Button from "../../primitives/Button.tsx"
import { readString } from "../shared/read.ts"

type Props = {
  orientation: BarOrientation
  command: string
}

const wifiIcons = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
const ethernetIcon = "󰀂"
const disconnectedIcon = "󰤮"

function selectWifiIcon(strength: number) {
  if (strength >= 80) return wifiIcons[4]
  if (strength >= 60) return wifiIcons[3]
  if (strength >= 40) return wifiIcons[2]
  if (strength >= 20) return wifiIcons[1]
  return wifiIcons[0]
}

function formatWifiTooltip(ssid: string, frequency: number): string {
  if (ssid.length === 0) return "Wi-Fi connected"
  if (frequency > 0) return `${ssid} (${(frequency / 1000).toFixed(1)} GHz)`
  return ssid
}

export default function NetworkWidget({ orientation, command }: Props) {
  const isVertical = orientation === "vertical"
  const network = AstalNetwork.get_default()

  const primary = createBinding(network, "primary")
  const networkState = createBinding(network, "state")
  const wifiRef = createBinding(network, "wifi")
  const wiredRef = createBinding(network, "wired")

  // Wifi sub-properties tracked via GObject signals so strength/ssid/frequency
  // changes propagate reactively without polling.
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

    if (!connected) return disconnectedIcon
    if (p === AstalNetwork.Primary.WIRED) return ethernetIcon
    if (p === AstalNetwork.Primary.WIFI) return selectWifiIcon(wifiStrength())

    const wiredIconName = readString(wiredRef()?.iconName)
    if (wiredIconName.length > 0 && wiredIconName !== "network-wired-disconnected-symbolic") {
      return ethernetIcon
    }
    return disconnectedIcon
  })

  const tooltipText = createComputed(() => {
    const p = primary()
    const s = networkState()
    const connected = typeof s === "number" && s >= AstalNetwork.State.CONNECTED_LOCAL

    if (!connected) return "Disconnected"
    if (p === AstalNetwork.Primary.WIRED) return "Ethernet connected"
    if (p === AstalNetwork.Primary.WIFI) return formatWifiTooltip(wifiSsid(), wifiFrequency())

    const wiredIconName = readString(wiredRef()?.iconName)
    if (wiredIconName.length > 0 && wiredIconName !== "network-wired-disconnected-symbolic") {
      return "Ethernet connected"
    }
    return "Disconnected"
  })

  return (
    <Button
      class="widget-network-button widget-glyph-button"
      orientation={orientation}
      execPrimary={() => execAsync(command).catch(() => {})}
      tooltipText={tooltipText}
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
