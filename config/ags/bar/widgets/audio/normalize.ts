import type { NormalizedSliderMetrics } from "../../primitives/sliderTypes.ts"
import type { AudioTooltipConfig, NormalizedAudioTooltipConfig, SliderMetrics } from "./types.ts"
import {
  childContext,
  normalizeBoolean,
  normalizeNonNegativeNumber,
  normalizeObjectConfig,
  normalizePositiveNumber,
  normalizeStringValue,
  type ValidationContext,
} from "../shared/normalize.ts"

export function normalizeAudioTooltipConfig(
  ctx: ValidationContext,
  config: AudioTooltipConfig | undefined,
  defaults: NormalizedAudioTooltipConfig,
): NormalizedAudioTooltipConfig {
  const raw = normalizeObjectConfig(ctx, config) as AudioTooltipConfig | undefined
  return {
    enabled: normalizeBoolean(childContext(ctx, "enabled"), raw?.enabled, defaults.enabled),
    active: normalizeStringValue(childContext(ctx, "active"), raw?.active, defaults.active),
    muted: normalizeStringValue(childContext(ctx, "muted"), raw?.muted, defaults.muted),
    unavailable: normalizeStringValue(childContext(ctx, "unavailable"), raw?.unavailable, defaults.unavailable),
  }
}

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
