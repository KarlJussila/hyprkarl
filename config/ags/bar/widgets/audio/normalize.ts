import type { NormalizedSliderMetrics } from "../../primitives/sliderTypes.ts"
import type {
  AudioTooltipConfig,
  NormalizedAudioTooltipConfig,
  SliderMetrics,
} from "./types.ts"
import {
  childContext,
  normalizeBoolean,
  normalizeNonNegativeNumber,
  normalizeObjectConfig,
  normalizePositiveNumber,
  normalizeStringValue,
  widgetContext,
} from "../shared/normalize.ts"

export function normalizeSliderMetrics(
  id: string,
  metrics: SliderMetrics | undefined,
  defaults: NormalizedSliderMetrics,
): NormalizedSliderMetrics {
  const context = widgetContext(id, "slider")
  const rawMetrics = normalizeObjectConfig(context, metrics)

  return {
    trackLength: normalizePositiveNumber(
      childContext(context, "trackLength"),
      rawMetrics?.trackLength,
      defaults.trackLength,
    ),
    trackThickness: normalizePositiveNumber(
      childContext(context, "trackThickness"),
      rawMetrics?.trackThickness,
      defaults.trackThickness,
    ),
    trackRadius: normalizeNonNegativeNumber(
      childContext(context, "trackRadius"),
      rawMetrics?.trackRadius,
      defaults.trackRadius,
    ),
    fillRadius: normalizeNonNegativeNumber(
      childContext(context, "fillRadius"),
      rawMetrics?.fillRadius,
      defaults.fillRadius,
    ),
    borderWidth: normalizeNonNegativeNumber(
      childContext(context, "borderWidth"),
      rawMetrics?.borderWidth,
      defaults.borderWidth,
    ),
    thumbWidth: normalizePositiveNumber(
      childContext(context, "thumbWidth"),
      rawMetrics?.thumbWidth,
      defaults.thumbWidth,
    ),
    thumbHeight: normalizePositiveNumber(
      childContext(context, "thumbHeight"),
      rawMetrics?.thumbHeight,
      defaults.thumbHeight,
    ),
    thumbRadius: normalizeNonNegativeNumber(
      childContext(context, "thumbRadius"),
      rawMetrics?.thumbRadius,
      defaults.thumbRadius,
    ),
    thumbVisible: normalizeBoolean(
      childContext(context, "thumbVisible"),
      rawMetrics?.thumbVisible,
      defaults.thumbVisible,
    ),
  }
}

export function normalizeAudioTooltipConfig(
  id: string,
  tooltip: AudioTooltipConfig | undefined,
  defaults: NormalizedAudioTooltipConfig,
): NormalizedAudioTooltipConfig {
  const context = widgetContext(id, "tooltip")
  const rawTooltip = normalizeObjectConfig(context, tooltip)

  return {
    active: normalizeStringValue(
      childContext(context, "active"),
      rawTooltip?.active,
      defaults.active,
    ),
    muted: normalizeStringValue(
      childContext(context, "muted"),
      rawTooltip?.muted,
      defaults.muted,
    ),
    unavailable: normalizeStringValue(
      childContext(context, "unavailable"),
      rawTooltip?.unavailable,
      defaults.unavailable,
    ),
  }
}
