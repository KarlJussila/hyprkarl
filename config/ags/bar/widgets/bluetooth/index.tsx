import { createBinding, createComputed } from "ags"
import { Gtk } from "ags/gtk4"
import AstalBluetooth from "gi://AstalBluetooth"
import Button from "../../primitives/Button.tsx"
import DeviceMenu from "./DeviceMenu.tsx"
import { substituteTokens } from "../shared/template.ts"
import { useWidgetCommands } from "../shared/useWidgetCommands.ts"
import { mergeConfig, defaultFlyout, type WidgetClicks, type WidgetFlyout, type WidgetProps } from "../shared/types.ts"

export type BluetoothConfig = {
  commands?: WidgetClicks
  flyout?: WidgetFlyout
  icons?: Partial<BluetoothIcons>
  tooltip?: Partial<BluetoothTooltip>
}

type BluetoothIcons = { enabled: string; disabled: string }

// Empty strings disable the corresponding tooltip state. If all three are
// empty the widget shows no tooltip at all.
type BluetoothTooltip = { off: string; on: string; connected: string }

type BluetoothDefaults = {
  commands: WidgetClicks
  flyout: WidgetFlyout
  icons: BluetoothIcons
  tooltip: BluetoothTooltip
}

export const defaults: BluetoothDefaults = {
  commands: { secondary: "hk-launch-bluetooth" },
  flyout: defaultFlyout,
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

export default function BluetoothWidget({ id, config, placement, monitor }: WidgetProps<BluetoothConfig>) {
  const cfg = mergeConfig(defaults, config)
  const { commands, flyout, icons, tooltip } = cfg
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

  const { execPrimary, execSecondary, execTertiary, triggerSetup } = useWidgetCommands({
    commands,
    flyout: {
      config: flyout,
      placement,
      monitor,
      id,
      label: "bluetooth-menu",
      renderContent: () => <DeviceMenu devices={devices} />,
    },
  })

  return (
    <Button
      class="widget-bluetooth-button widget-glyph-button"
      orientation={placement.orientation}
      tooltipText={tooltipText}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execTertiary={execTertiary}
      $={triggerSetup}
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
