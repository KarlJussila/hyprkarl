import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  composeObject,
  normalizeBoolean,
  normalizeClickCommandsConfig,
  normalizeStringValue,
} from "../shared/normalize.ts"
import { normalizeWifiIcons } from "./normalize.ts"
import NetworkWidget from "./NetworkWidget.tsx"

const normalizeNetworkIcons = composeObject({
  disconnected: normalizeStringValue,
  ethernet: normalizeStringValue,
  wifi: normalizeWifiIcons,
})

const normalizeNetworkTooltipConfig = composeObject({
  enabled: normalizeBoolean,
  disconnected: normalizeStringValue,
  ethernet: normalizeStringValue,
  wifi: normalizeStringValue,
  wifiNoFreq: normalizeStringValue,
  wifiNoSsid: normalizeStringValue,
})

export default createWidgetSpec({
  kind: "network",
  defaults: {
    commands: {
      primary: "hk-launch-wifi",
      secondary: undefined,
      tertiary: undefined,
    },
    icons: {
      disconnected: "󰤮",
      ethernet: "󰀂",
      wifi: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"],
    },
    tooltip: {
      enabled: true,
      disconnected: "Disconnected",
      ethernet: "Ethernet connected",
      wifi: "{ssid} ({freq} GHz)",
      wifiNoFreq: "{ssid}",
      wifiNoSsid: "Wi-Fi connected",
    },
  },
  schema: {
    commands: normalizeClickCommandsConfig,
    icons: normalizeNetworkIcons,
    tooltip: normalizeNetworkTooltipConfig,
  },
  render: (args) => (
    <NetworkWidget {...args} />
  ),
})
