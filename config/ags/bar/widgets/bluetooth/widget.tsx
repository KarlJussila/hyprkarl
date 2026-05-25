import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizeRequiredCommand, normalizeStringRecord } from "../shared/normalize.ts"
import {
  normalizeBluetoothTooltipConfig,
  type NormalizedBluetoothIcons,
  type NormalizedBluetoothTooltip,
} from "./normalize.ts"
import BluetoothWidget from "./BluetoothWidget.tsx"

export default createWidgetSpec({
  kind: "bluetooth",
  defaults: {
    command: "hk-launch-bluetooth",
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
    command: normalizeRequiredCommand,
    icons: normalizeStringRecord,
    tooltip: normalizeBluetoothTooltipConfig,
  },
  render: ({ config, placement }) => (
    <BluetoothWidget
      orientation={placement.orientation}
      command={config.command}
      icons={config.icons}
      tooltip={config.tooltip}
    />
  ),
})
