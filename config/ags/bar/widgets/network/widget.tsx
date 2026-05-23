import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizeRequiredCommand, normalizeStringRecord } from "../shared/normalize.ts"
import { normalizeNetworkIcons } from "./normalize.ts"
import type { NormalizedNetworkIcons, NormalizedNetworkTooltip } from "./normalize.ts"
import NetworkWidget from "./NetworkWidget.tsx"

export default createWidgetSpec({
  kind: "network",
  defaults: {
    command: "hk-launch-wifi",
    icons: {
      disconnected: "󰤮",
      ethernet: "󰀂",
      wifi: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"],
    } satisfies NormalizedNetworkIcons,
    tooltip: {
      disconnected: "Disconnected",
      ethernet: "Ethernet connected",
      wifi: "{ssid} ({freq} GHz)",
      wifiNoFreq: "{ssid}",
      wifiNoSsid: "Wi-Fi connected",
    } satisfies NormalizedNetworkTooltip,
  },
  schema: {
    command: normalizeRequiredCommand,
    icons: normalizeNetworkIcons,
    tooltip: normalizeStringRecord,
  },
  render: ({ config, placement }) => (
    <NetworkWidget
      orientation={placement.orientation}
      command={config.command}
      icons={config.icons}
      tooltip={config.tooltip}
    />
  ),
})
