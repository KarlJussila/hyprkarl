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
  type ValidationContext,
} from "../shared/normalize.ts"

export function normalizeBatteryIndicatorMetrics(
  ctx: ValidationContext,
  metrics: BatteryIndicatorMetrics | undefined,
  defaults: NormalizedBatteryIndicatorMetrics,
): NormalizedBatteryIndicatorMetrics {
  const rawMetrics = normalizeObjectConfig(ctx, metrics) as BatteryIndicatorMetrics | undefined

  return {
    width: normalizePositiveNumber(childContext(ctx, "width"), rawMetrics?.width, defaults.width),
    height: normalizePositiveNumber(childContext(ctx, "height"), rawMetrics?.height, defaults.height),
    borderWidth: normalizeNonNegativeNumber(childContext(ctx, "borderWidth"), rawMetrics?.borderWidth, defaults.borderWidth),
    terminalWidth: normalizePositiveNumber(childContext(ctx, "terminalWidth"), rawMetrics?.terminalWidth, defaults.terminalWidth),
    terminalHeight: normalizePositiveNumber(childContext(ctx, "terminalHeight"), rawMetrics?.terminalHeight, defaults.terminalHeight),
    chargingGlyph: normalizeStringValue(childContext(ctx, "chargingGlyph"), rawMetrics?.chargingGlyph, defaults.chargingGlyph),
    chargingGlyphFontSize: normalizePositiveNumber(childContext(ctx, "chargingGlyphFontSize"), rawMetrics?.chargingGlyphFontSize, defaults.chargingGlyphFontSize),
    chargingGlyphFontFamily: normalizeStringValue(childContext(ctx, "chargingGlyphFontFamily"), rawMetrics?.chargingGlyphFontFamily, defaults.chargingGlyphFontFamily),
  }
}

export function normalizeBatteryTooltipConfig(
  ctx: ValidationContext,
  tooltip: BatteryTooltipConfig | undefined,
  defaults: NormalizedBatteryTooltipConfig,
): NormalizedBatteryTooltipConfig {
  const rawTooltip = normalizeObjectConfig(ctx, tooltip) as BatteryTooltipConfig | undefined

  return {
    charging: normalizeStringValue(childContext(ctx, "charging"), rawTooltip?.charging, defaults.charging),
    discharging: normalizeStringValue(childContext(ctx, "discharging"), rawTooltip?.discharging, defaults.discharging),
    plugged: normalizeStringValue(childContext(ctx, "plugged"), rawTooltip?.plugged, defaults.plugged),
    fallback: normalizeStringValue(childContext(ctx, "fallback"), rawTooltip?.fallback, defaults.fallback),
  }
}
