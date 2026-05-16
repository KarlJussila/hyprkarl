import type {
  ClockDisplayConfig,
  NormalizedClockDisplayConfig,
} from "./types.ts"
import {
  childContext,
  normalizeObjectConfig,
  normalizeStringValue,
  widgetContext,
} from "../shared/normalize.ts"

export function normalizeClockDisplay(
  id: string,
  display: ClockDisplayConfig | undefined,
  defaults: NormalizedClockDisplayConfig,
) {
  const context = widgetContext(id, "display")
  const rawDisplay = normalizeObjectConfig(context, display)
  const rawVertical = normalizeObjectConfig(childContext(context, "vertical"), rawDisplay?.vertical)

  return {
    horizontal: normalizeStringValue(
      childContext(context, "horizontal"),
      rawDisplay?.horizontal,
      defaults.horizontal,
    ),
    vertical: {
      top: normalizeStringValue(
        childContext(context, "vertical.top"),
        rawVertical?.top,
        defaults.vertical.top,
      ),
      middle: normalizeStringValue(
        childContext(context, "vertical.middle"),
        rawVertical?.middle,
        defaults.vertical.middle,
      ),
      bottom: normalizeStringValue(
        childContext(context, "vertical.bottom"),
        rawVertical?.bottom,
        defaults.vertical.bottom,
      ),
    },
  }
}
