import type { NormalizedSliderMetrics } from "../../primitives/sliderTypes.ts"
import type { SliderMetrics } from "./types.ts"
import {
  childContext,
  normalizeBoolean,
  normalizeNonNegativeNumber,
  normalizeObjectConfig,
  normalizePositiveNumber,
  type ValidationContext,
} from "../shared/normalize.ts"

export function normalizeSliderMetrics(
  ctx: ValidationContext,
  metrics: SliderMetrics | undefined,
  defaults: NormalizedSliderMetrics,
): NormalizedSliderMetrics {
  const rawMetrics = normalizeObjectConfig(ctx, metrics) as SliderMetrics | undefined

  return {
    trackLength: normalizePositiveNumber(childContext(ctx, "trackLength"), rawMetrics?.trackLength, defaults.trackLength),
    trackThickness: normalizePositiveNumber(childContext(ctx, "trackThickness"), rawMetrics?.trackThickness, defaults.trackThickness),
    trackRadius: normalizeNonNegativeNumber(childContext(ctx, "trackRadius"), rawMetrics?.trackRadius, defaults.trackRadius),
    fillRadius: normalizeNonNegativeNumber(childContext(ctx, "fillRadius"), rawMetrics?.fillRadius, defaults.fillRadius),
    borderWidth: normalizeNonNegativeNumber(childContext(ctx, "borderWidth"), rawMetrics?.borderWidth, defaults.borderWidth),
    thumbWidth: normalizePositiveNumber(childContext(ctx, "thumbWidth"), rawMetrics?.thumbWidth, defaults.thumbWidth),
    thumbHeight: normalizePositiveNumber(childContext(ctx, "thumbHeight"), rawMetrics?.thumbHeight, defaults.thumbHeight),
    thumbRadius: normalizeNonNegativeNumber(childContext(ctx, "thumbRadius"), rawMetrics?.thumbRadius, defaults.thumbRadius),
    thumbVisible: normalizeBoolean(childContext(ctx, "thumbVisible"), rawMetrics?.thumbVisible, defaults.thumbVisible),
  }
}
