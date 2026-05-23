import { createBinding, createComputed } from "ags"
import { execAsync } from "ags/process"
import { Gtk } from "ags/gtk4"
import AstalBluetooth from "gi://AstalBluetooth"
import { type BarOrientation } from "../../layout/placement.ts"
import Button from "../../primitives/Button.tsx"
import { substituteTokens } from "../shared/template.ts"
import type { NormalizedBluetoothIcons, NormalizedBluetoothTooltip } from "./normalize.ts"

type Props = {
  orientation: BarOrientation
  command: string
  icons: NormalizedBluetoothIcons
  tooltip: NormalizedBluetoothTooltip
}

function countConnectedDevices(devices: Array<any>) {
  return devices.filter((device) => {
    try {
      return Boolean(device.connected)
    } catch {
      return false
    }
  }).length
}

export default function BluetoothWidget({ orientation, command, icons, tooltip }: Props) {
  const isVertical = orientation === "vertical"
  const bluetooth = AstalBluetooth.get_default()
  const isPowered = createBinding(bluetooth, "isPowered")
  const isConnected = createBinding(bluetooth, "isConnected")
  const devices = createBinding(bluetooth, "devices")

  const icon = createComputed(() => isPowered() ? icons.enabled : icons.disabled)
  const tooltipText = createComputed(() => {
    if (!isPowered()) return tooltip.off
    if (!isConnected()) return tooltip.on
    return substituteTokens(tooltip.connected, { count: String(countConnectedDevices(devices())) })
  })

  return (
    <Button
      class="widget-bluetooth-button widget-glyph-button"
      orientation={orientation}
      tooltipText={tooltipText}
      execPrimary={() => execAsync(command).catch(() => {})}
    >
      <box
        class="widget-bluetooth-content"
        hexpand={isVertical}
        halign={Gtk.Align.CENTER}
      >
        <label class="widget-bluetooth-glyph" xalign={0.5} label={icon} />
      </box>
    </Button>
  )
}
