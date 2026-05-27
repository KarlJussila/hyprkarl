import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  composeObject,
  normalizeBoolean,
  normalizeNonNegativeNumber,
  normalizePositiveNumber,
  normalizeStringValue,
  normalizeUnitInterval,
} from "../shared/normalize.ts"
import { flyoutWidgetSchema, flyoutWidgetDefaults } from "../shared/widgetKit.ts"
import BatteryWidget from "./BatteryWidget.tsx"

const normalizeBatteryIndicatorMetrics = composeObject({
  width: normalizePositiveNumber,
  height: normalizePositiveNumber,
  borderWidth: normalizeNonNegativeNumber,
  terminalWidth: normalizePositiveNumber,
  terminalHeight: normalizePositiveNumber,
  chargingGlyph: normalizeStringValue,
  chargingGlyphFontSize: normalizePositiveNumber,
  chargingGlyphFontFamily: normalizeStringValue,
})

const normalizeBatteryTooltipConfig = composeObject({
  enabled: normalizeBoolean,
  charging: normalizeStringValue,
  discharging: normalizeStringValue,
  plugged: normalizeStringValue,
  fallback: normalizeStringValue,
})

const batteryDefaults = {
  ...flyoutWidgetDefaults,
  showPercentage: true,
  lowThreshold: 0.15,
  tooltip: {
    enabled: true,
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
}

export default createWidgetSpec({
  kind: "battery",
  defaults: batteryDefaults,
  schema: {
    ...flyoutWidgetSchema,
    showPercentage: normalizeBoolean,
    lowThreshold: normalizeUnitInterval,
    tooltip: normalizeBatteryTooltipConfig,
    indicator: normalizeBatteryIndicatorMetrics,
  },
  render: (args) => (
    <BatteryWidget {...args} />
  ),
})
