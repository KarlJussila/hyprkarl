import type {
  BatteryIndicatorMetrics,
  BatteryTooltipConfig,
  NormalizedBatteryIndicatorMetrics,
  NormalizedBatteryTooltipConfig,
} from "./types.ts"
import {
  childContext,
  normalizeNonNegativeNumber,
  normalizeObjectConfig,
  normalizePositiveNumber,
  normalizeStringValue,
  widgetContext,
} from "../shared/normalize.ts"

export function normalizeBatteryIndicatorMetrics(
  id: string,
  metrics: BatteryIndicatorMetrics | undefined,
  defaults: NormalizedBatteryIndicatorMetrics,
): NormalizedBatteryIndicatorMetrics {
  const context = widgetContext(id, "indicator")
  const rawMetrics = normalizeObjectConfig(context, metrics)

  return {
    width: normalizePositiveNumber(
      childContext(context, "width"),
      rawMetrics?.width,
      defaults.width,
    ),
    height: normalizePositiveNumber(
      childContext(context, "height"),
      rawMetrics?.height,
      defaults.height,
    ),
    borderWidth: normalizeNonNegativeNumber(
      childContext(context, "borderWidth"),
      rawMetrics?.borderWidth,
      defaults.borderWidth,
    ),
    terminalWidth: normalizePositiveNumber(
      childContext(context, "terminalWidth"),
      rawMetrics?.terminalWidth,
      defaults.terminalWidth,
    ),
    terminalHeight: normalizePositiveNumber(
      childContext(context, "terminalHeight"),
      rawMetrics?.terminalHeight,
      defaults.terminalHeight,
    ),
    chargingGlyph: normalizeStringValue(
      childContext(context, "chargingGlyph"),
      rawMetrics?.chargingGlyph,
      defaults.chargingGlyph,
    ),
    chargingGlyphFontSize: normalizePositiveNumber(
      childContext(context, "chargingGlyphFontSize"),
      rawMetrics?.chargingGlyphFontSize,
      defaults.chargingGlyphFontSize,
    ),
    chargingGlyphFontFamily: normalizeStringValue(
      childContext(context, "chargingGlyphFontFamily"),
      rawMetrics?.chargingGlyphFontFamily,
      defaults.chargingGlyphFontFamily,
    ),
  }
}

export function normalizeBatteryTooltipConfig(
  id: string,
  tooltip: BatteryTooltipConfig | undefined,
  defaults: NormalizedBatteryTooltipConfig,
): NormalizedBatteryTooltipConfig {
  const context = widgetContext(id, "tooltip")
  const rawTooltip = normalizeObjectConfig(context, tooltip)

  return {
    charging: normalizeStringValue(
      childContext(context, "charging"),
      rawTooltip?.charging,
      defaults.charging,
    ),
    discharging: normalizeStringValue(
      childContext(context, "discharging"),
      rawTooltip?.discharging,
      defaults.discharging,
    ),
    plugged: normalizeStringValue(
      childContext(context, "plugged"),
      rawTooltip?.plugged,
      defaults.plugged,
    ),
    fallback: normalizeStringValue(
      childContext(context, "fallback"),
      rawTooltip?.fallback,
      defaults.fallback,
    ),
  }
}
