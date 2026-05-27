import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  normalizeClickCommandsConfig,
  type NormalizedClickCommandsConfig,
} from "../shared/normalize.ts"
import { normalizeNetworkIcons, normalizeNetworkTooltipConfig } from "./normalize.ts"
import type { NormalizedNetworkIcons, NormalizedNetworkTooltip } from "./normalize.ts"
import NetworkWidget from "./NetworkWidget.tsx"

export default createWidgetSpec({
  kind: "network",
  defaults: {
    commands: {
      primary: "hk-launch-wifi",
      secondary: undefined,
      tertiary: undefined,
    } satisfies NormalizedClickCommandsConfig,
    icons: {
      disconnected: "󰤮",
      ethernet: "󰀂",
      wifi: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"],
    } satisfies NormalizedNetworkIcons,
    tooltip: {
      enabled: true,
      disconnected: "Disconnected",
      ethernet: "Ethernet connected",
      wifi: "{ssid} ({freq} GHz)",
      wifiNoFreq: "{ssid}",
      wifiNoSsid: "Wi-Fi connected",
    } satisfies NormalizedNetworkTooltip,
  },
  schema: {
    commands: normalizeClickCommandsConfig,
    icons: normalizeNetworkIcons,
    tooltip: normalizeNetworkTooltipConfig,
  },
  render: ({ config, placement }) => (
    <NetworkWidget
      orientation={placement.orientation}
      commands={config.commands}
      icons={config.icons}
      tooltip={config.tooltip}
    />
  ),
})
