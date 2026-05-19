import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizeBoolean, normalizeUnitInterval } from "../shared/normalize.ts"
import { normalizeFlyoutConfig } from "../shared/normalizeFlyout.ts"
import type { NormalizedFlyoutConfig } from "../shared/flyoutTypes.ts"
import { normalizeBatteryIndicatorMetrics, normalizeBatteryTooltipConfig } from "./normalize.ts"
import type {
  NormalizedBatteryIndicatorMetrics,
  NormalizedBatteryTooltipConfig,
} from "./types.ts"
import BatteryWidget from "./BatteryWidget.tsx"

const batteryDefaults = {
  showPercentage: true,
  lowThreshold: 0.15,
  flyout: {
    enabled: true,
    align: "center",
    gap: 0,
  },
  tooltip: {
    charging: "{power}↑ {time}",
    discharging: "{power}↓ {time}",
    plugged: "Plugged in {percentage}",
    fallback: "{percentage}",
  },
  indicator: {
    width: 14,
    height: 8,
    borderWidth: 1,
    terminalWidth: 2,
    terminalHeight: 4,
    chargingGlyph: "󱐋",
    chargingGlyphFontSize: 6,
    chargingGlyphFontFamily: "JetBrains Mono Nerd Font Propo",
  },
} satisfies {
  showPercentage: boolean
  lowThreshold: number
  flyout: NormalizedFlyoutConfig
  tooltip: NormalizedBatteryTooltipConfig
  indicator: NormalizedBatteryIndicatorMetrics
}

export default createWidgetSpec({
  kind: "battery",
  defaults: batteryDefaults,
  schema: {
    showPercentage: normalizeBoolean,
    lowThreshold: normalizeUnitInterval,
    flyout: normalizeFlyoutConfig,
    tooltip: normalizeBatteryTooltipConfig,
    indicator: normalizeBatteryIndicatorMetrics,
  },
  render: ({ id, config, placement, monitor }) => (
    <BatteryWidget
      id={id}
      placement={placement}
      monitor={monitor}
      showPercentage={config.showPercentage}
      lowThreshold={config.lowThreshold}
      flyout={config.flyout}
      tooltip={config.tooltip}
      indicator={config.indicator}
    />
  ),
})
