import type { NormalizedSwitchMetrics } from "../../primitives/switchTypes.ts"
import type { SwitchMetrics } from "./types.ts"
import {
  childContext,
  normalizeFiniteNumber,
  normalizeNonNegativeNumber,
  normalizeObjectConfig,
  normalizePositiveNumber,
  normalizeStringValue,
  type ValidationContext,
} from "../shared/normalize.ts"

export function normalizeSwitchMetrics(
  ctx: ValidationContext,
  metrics: SwitchMetrics | undefined,
  defaults: NormalizedSwitchMetrics,
): NormalizedSwitchMetrics {
  const rawMetrics = normalizeObjectConfig(ctx, metrics) as SwitchMetrics | undefined

  return {
    thumbSize: normalizePositiveNumber(childContext(ctx, "thumbSize"), rawMetrics?.thumbSize, defaults.thumbSize),
    trackHeight: normalizePositiveNumber(childContext(ctx, "trackHeight"), rawMetrics?.trackHeight, defaults.trackHeight),
    trackLength: normalizePositiveNumber(childContext(ctx, "trackLength"), rawMetrics?.trackLength, defaults.trackLength),
    thumbPadding: normalizeNonNegativeNumber(childContext(ctx, "thumbPadding"), rawMetrics?.thumbPadding, defaults.thumbPadding),
    glyphOffsetX: normalizeFiniteNumber(childContext(ctx, "glyphOffsetX"), rawMetrics?.glyphOffsetX, defaults.glyphOffsetX),
    glyphOffsetY: normalizeFiniteNumber(childContext(ctx, "glyphOffsetY"), rawMetrics?.glyphOffsetY, defaults.glyphOffsetY),
    borderWidth: normalizeNonNegativeNumber(childContext(ctx, "borderWidth"), rawMetrics?.borderWidth, defaults.borderWidth),
    fontSize: normalizePositiveNumber(childContext(ctx, "fontSize"), rawMetrics?.fontSize, defaults.fontSize),
    fontFamily: normalizeStringValue(childContext(ctx, "fontFamily"), rawMetrics?.fontFamily, defaults.fontFamily),
  }
}
