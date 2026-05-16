import type { NormalizedSwitchMetrics } from "../../primitives/switchTypes.ts"
import type { SwitchMetrics } from "./types.ts"
import {
  childContext,
  normalizeFiniteNumber,
  normalizeNonNegativeNumber,
  normalizeObjectConfig,
  normalizePositiveNumber,
  normalizeStringValue,
  widgetContext,
} from "../shared/normalize.ts"

export function normalizeSwitchMetrics(
  id: string,
  metrics: SwitchMetrics | undefined,
  defaults: NormalizedSwitchMetrics,
): NormalizedSwitchMetrics {
  const context = widgetContext(id, "switch")
  const rawMetrics = normalizeObjectConfig(context, metrics)

  return {
    thumbSize: normalizePositiveNumber(
      childContext(context, "thumbSize"),
      rawMetrics?.thumbSize,
      defaults.thumbSize,
    ),
    trackHeight: normalizePositiveNumber(
      childContext(context, "trackHeight"),
      rawMetrics?.trackHeight,
      defaults.trackHeight,
    ),
    trackLength: normalizePositiveNumber(
      childContext(context, "trackLength"),
      rawMetrics?.trackLength,
      defaults.trackLength,
    ),
    thumbPadding: normalizeNonNegativeNumber(
      childContext(context, "thumbPadding"),
      rawMetrics?.thumbPadding,
      defaults.thumbPadding,
    ),
    glyphOffsetX: normalizeFiniteNumber(
      childContext(context, "glyphOffsetX"),
      rawMetrics?.glyphOffsetX,
      defaults.glyphOffsetX,
    ),
    glyphOffsetY: normalizeFiniteNumber(
      childContext(context, "glyphOffsetY"),
      rawMetrics?.glyphOffsetY,
      defaults.glyphOffsetY,
    ),
    borderWidth: normalizeNonNegativeNumber(
      childContext(context, "borderWidth"),
      rawMetrics?.borderWidth,
      defaults.borderWidth,
    ),
    fontSize: normalizePositiveNumber(
      childContext(context, "fontSize"),
      rawMetrics?.fontSize,
      defaults.fontSize,
    ),
    fontFamily: normalizeStringValue(
      childContext(context, "fontFamily"),
      rawMetrics?.fontFamily,
      defaults.fontFamily,
    ),
  }
}
