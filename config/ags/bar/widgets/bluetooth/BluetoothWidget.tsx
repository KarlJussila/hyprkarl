import { createBinding, createComputed } from "ags"
import { Gtk } from "ags/gtk4"
import AstalBluetooth from "gi://AstalBluetooth"
import { type BarOrientation } from "../../layout/placement.ts"
import Button from "../../primitives/Button.tsx"
import { resolveCommand } from "../shared/resolveCommand.ts"
import { substituteTokens } from "../shared/template.ts"
import type { NormalizedClickCommandsConfig } from "../shared/normalize.ts"
import type { NormalizedBluetoothIcons, NormalizedBluetoothTooltip } from "./normalize.ts"

type Props = {
  orientation: BarOrientation
  commands: NormalizedClickCommandsConfig
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

export default function BluetoothWidget({ orientation, commands, icons, tooltip }: Props) {
  const isVertical = orientation === "vertical"
  const bluetooth = AstalBluetooth.get_default()
  const isPowered = createBinding(bluetooth, "isPowered")
  const isConnected = createBinding(bluetooth, "isConnected")
  const devices = createBinding(bluetooth, "devices")

  const icon = createComputed(() => isPowered() ? icons.enabled : icons.disabled)
  const tooltipText = tooltip.enabled
    ? createComputed(() => {
        if (!isPowered()) return tooltip.off
        if (!isConnected()) return tooltip.on
        return substituteTokens(tooltip.connected, { count: String(countConnectedDevices(devices())) })
      })
    : undefined

  const execPrimary = resolveCommand(commands.primary, undefined)
  const execSecondary = resolveCommand(commands.secondary, undefined)
  const execMiddle = resolveCommand(commands.tertiary, undefined)

  return (
    <Button
      class="widget-bluetooth-button widget-glyph-button"
      orientation={orientation}
      tooltipText={tooltipText}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execMiddle={execMiddle}
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
