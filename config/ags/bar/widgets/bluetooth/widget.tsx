import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizeRequiredCommand, normalizeStringRecord } from "../shared/normalize.ts"
import type { NormalizedBluetoothIcons, NormalizedBluetoothTooltip } from "./normalize.ts"
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
      off: "Bluetooth off",
      on: "Bluetooth on",
      connected: "Devices connected: {count}",
    } satisfies NormalizedBluetoothTooltip,
  },
  schema: {
    command: normalizeRequiredCommand,
    icons: normalizeStringRecord,
    tooltip: normalizeStringRecord,
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
