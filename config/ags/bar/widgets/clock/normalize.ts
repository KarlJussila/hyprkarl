import type {
  ClockDisplayConfig,
  NormalizedClockDisplayConfig,
} from "./types.ts"
import {
  childContext,
  normalizeObjectConfig,
  normalizeStringValue,
  type ValidationContext,
} from "../shared/normalize.ts"

export function normalizeClockDisplay(
  ctx: ValidationContext,
  display: ClockDisplayConfig | undefined,
  defaults: NormalizedClockDisplayConfig,
): NormalizedClockDisplayConfig {
  const rawDisplay = normalizeObjectConfig(ctx, display) as ClockDisplayConfig | undefined
  const rawVertical = normalizeObjectConfig(
    childContext(ctx, "vertical"),
    rawDisplay?.vertical,
  ) as ClockDisplayConfig["vertical"] | undefined

  return {
    horizontal: normalizeStringValue(childContext(ctx, "horizontal"), rawDisplay?.horizontal, defaults.horizontal),
    vertical: {
      top: normalizeStringValue(childContext(ctx, "vertical.top"), rawVertical?.top, defaults.vertical.top),
      middle: normalizeStringValue(childContext(ctx, "vertical.middle"), rawVertical?.middle, defaults.vertical.middle),
      bottom: normalizeStringValue(childContext(ctx, "vertical.bottom"), rawVertical?.bottom, defaults.vertical.bottom),
    },
  }
}
