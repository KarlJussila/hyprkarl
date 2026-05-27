import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  composeObject,
  normalizeBoolean,
  normalizeClickCommandsConfig,
  normalizeStringValue,
} from "../shared/normalize.ts"
import BluetoothWidget from "./BluetoothWidget.tsx"

const normalizeBluetoothIcons = composeObject({
  enabled: normalizeStringValue,
  disabled: normalizeStringValue,
})

const normalizeBluetoothTooltipConfig = composeObject({
  enabled: normalizeBoolean,
  off: normalizeStringValue,
  on: normalizeStringValue,
  connected: normalizeStringValue,
})

export default createWidgetSpec({
  kind: "bluetooth",
  defaults: {
    commands: {
      primary: "hk-launch-bluetooth",
      secondary: undefined,
      tertiary: undefined,
    },
    icons: {
      enabled: "",
      disabled: "󰂲",
    },
    tooltip: {
      enabled: true,
      off: "Bluetooth off",
      on: "Bluetooth on",
      connected: "Devices connected: {count}",
    },
  },
  schema: {
    commands: normalizeClickCommandsConfig,
    icons: normalizeBluetoothIcons,
    tooltip: normalizeBluetoothTooltipConfig,
  },
  render: (args) => (
    <BluetoothWidget {...args} />
  ),
})
