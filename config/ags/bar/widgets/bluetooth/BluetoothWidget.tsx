import { createBinding, createComputed } from "ags"
import { Gtk } from "ags/gtk4"
import AstalBluetooth from "gi://AstalBluetooth"
import Button from "../../primitives/Button.tsx"
import { substituteTokens } from "../shared/template.ts"
import { useWidgetCommands } from "../shared/useWidgetCommands.ts"
import type { WidgetRenderArgs } from "../shared/widgetSpec.tsx"
import type { NormalizedClickCommandsConfig } from "../shared/normalize.ts"

type Config = {
  commands: NormalizedClickCommandsConfig
  icons: { enabled: string; disabled: string }
  tooltip: { enabled: boolean; off: string; on: string; connected: string }
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

export default function BluetoothWidget({ config, placement }: WidgetRenderArgs<Config>) {
  const { commands, icons, tooltip } = config
  const isVertical = placement.orientation === "vertical"
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

  const { execPrimary, execSecondary, execMiddle } = useWidgetCommands({ commands })

  return (
    <Button
      class="widget-bluetooth-button widget-glyph-button"
      orientation={placement.orientation}
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
