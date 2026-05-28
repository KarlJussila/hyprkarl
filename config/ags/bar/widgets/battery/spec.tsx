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
import { normalizeGlyph } from "../../primitives/glyphNormalize.ts"
import BatteryWidget from "./BatteryWidget.tsx"

const normalizeBatteryIndicatorGlyphs = composeObject({
  charging: normalizeGlyph,
})

const normalizeBatteryIndicatorMetrics = composeObject({
  width: normalizePositiveNumber,
  height: normalizePositiveNumber,
  borderWidth: normalizeNonNegativeNumber,
  terminalWidth: normalizePositiveNumber,
  terminalHeight: normalizePositiveNumber,
  fontSize: normalizePositiveNumber,
  fontFamily: normalizeStringValue,
  glyphs: normalizeBatteryIndicatorGlyphs,
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
    fontSize: 6,
    fontFamily: "JetBrains Mono Nerd Font Propo",
    glyphs: {
      charging: { glyph: "󱐋", glyphOffset: [0, 0] as [number, number] },
    },
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
