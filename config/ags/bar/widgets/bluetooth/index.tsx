import { createBinding, createComputed } from "ags"
import { Gtk } from "ags/gtk4"
import AstalBluetooth from "gi://AstalBluetooth"
import Button from "../../primitives/Button.tsx"
import { substituteTokens } from "../shared/template.ts"
import { useWidgetCommands } from "../shared/useWidgetCommands.ts"
import { mergeConfig, type WidgetClicks, type WidgetProps } from "../shared/types.ts"

export type BluetoothConfig = {
  commands?: WidgetClicks
  icons?: Partial<BluetoothIcons>
  tooltip?: Partial<BluetoothTooltip>
}

type BluetoothIcons = { enabled: string; disabled: string }

// Empty strings disable the corresponding tooltip state. If all three are
// empty the widget shows no tooltip at all.
type BluetoothTooltip = { off: string; on: string; connected: string }

type BluetoothDefaults = {
  commands: WidgetClicks
  icons: BluetoothIcons
  tooltip: BluetoothTooltip
}

export const defaults: BluetoothDefaults = {
  commands: { primary: "hk-launch-bluetooth" },
  icons: {
    enabled: "",
    disabled: "󰂲",
  },
  tooltip: {
    off: "Bluetooth off",
    on: "Bluetooth on",
    connected: "Devices connected: {count}",
  },
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

export default function BluetoothWidget({ config, placement }: WidgetProps<BluetoothConfig>) {
  const cfg = mergeConfig(defaults, config)
  const { commands, icons, tooltip } = cfg
  const isVertical = placement.orientation === "vertical"
  const bluetooth = AstalBluetooth.get_default()
  const isPowered = createBinding(bluetooth, "isPowered")
  const isConnected = createBinding(bluetooth, "isConnected")
  const devices = createBinding(bluetooth, "devices")

  const tooltipEnabled = Boolean(tooltip.off || tooltip.on || tooltip.connected)

  const icon = createComputed(() => isPowered() ? icons.enabled : icons.disabled)
  const tooltipText = tooltipEnabled
    ? createComputed(() => {
        if (!isPowered()) return tooltip.off
        if (!isConnected()) return tooltip.on
        return substituteTokens(tooltip.connected, { count: String(countConnectedDevices(devices())) })
      })
    : undefined

  const { execPrimary, execSecondary, execTertiary } = useWidgetCommands({ commands })

  return (
    <Button
      class="widget-bluetooth-button widget-glyph-button"
      orientation={placement.orientation}
      tooltipText={tooltipText}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execTertiary={execTertiary}
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
