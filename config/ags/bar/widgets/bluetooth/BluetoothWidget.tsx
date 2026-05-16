import { createBinding, createComputed } from "ags"
import { execAsync } from "ags/process"
import { Gtk } from "ags/gtk4"
import AstalBluetooth from "gi://AstalBluetooth"
import { type BarOrientation } from "../../layout/placement.ts"
import Button from "../../primitives/Button.tsx"

type Props = {
  orientation: BarOrientation
  command: string
}

const enabledIcon = ""
const disabledIcon = "󰂲"

function countConnectedDevices(devices: Array<any>) {
  return devices.filter((device) => {
    try {
      return Boolean(device.connected)
    } catch {
      return false
    }
  }).length
}

export default function BluetoothWidget({ orientation, command }: Props) {
  const isVertical = orientation === "vertical"
  const bluetooth = AstalBluetooth.get_default()
  const isPowered = createBinding(bluetooth, "isPowered")
  const isConnected = createBinding(bluetooth, "isConnected")
  const devices = createBinding(bluetooth, "devices")

  const icon = createComputed(() => isPowered() ? enabledIcon : disabledIcon)
  const tooltipText = createComputed(() => {
    if (!isPowered()) {
      return "Bluetooth off"
    }

    if (!isConnected()) {
      return "Bluetooth on"
    }

    return `Devices connected: ${countConnectedDevices(devices())}`
  })

  return (
    <Button
      class="widget-bluetooth-button"
      hexpand={isVertical}
      halign={isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
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
