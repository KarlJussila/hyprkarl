import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  normalizeClickCommandsConfig,
  type NormalizedClickCommandsConfig,
} from "../shared/normalize.ts"
import {
  normalizeBluetoothIcons,
  normalizeBluetoothTooltipConfig,
  type NormalizedBluetoothIcons,
  type NormalizedBluetoothTooltip,
} from "./normalize.ts"
import BluetoothWidget from "./BluetoothWidget.tsx"

export default createWidgetSpec({
  kind: "bluetooth",
  defaults: {
    commands: {
      primary: "hk-launch-bluetooth",
      secondary: undefined,
      tertiary: undefined,
    } satisfies NormalizedClickCommandsConfig,
    icons: {
      enabled: "",
      disabled: "󰂲",
    } satisfies NormalizedBluetoothIcons,
    tooltip: {
      enabled: true,
      off: "Bluetooth off",
      on: "Bluetooth on",
      connected: "Devices connected: {count}",
    } satisfies NormalizedBluetoothTooltip,
  },
  schema: {
    commands: normalizeClickCommandsConfig,
    icons: normalizeBluetoothIcons,
    tooltip: normalizeBluetoothTooltipConfig,
  },
  render: ({ config, placement }) => (
    <BluetoothWidget
      orientation={placement.orientation}
      commands={config.commands}
      icons={config.icons}
      tooltip={config.tooltip}
    />
  ),
})
