import type {
  NormalizedTrayRevealConfig,
  TrayDirection,
  TrayRevealConfig,
} from "./types.ts"
import {
  childContext,
  fail,
  normalizeObjectConfig,
  normalizePositiveNumber,
  widgetContext,
} from "../shared/normalize.ts"

export function normalizeTrayDirection(
  id: string,
  value: unknown,
  fallback: TrayDirection,
): TrayDirection {
  const direction = value ?? fallback
  if (direction !== "start" && direction !== "end") {
    fail(widgetContext(id, "direction"), 'must be "start" or "end"')
  }

  return direction
}

export function normalizeRevealConfig(
  id: string,
  reveal: TrayRevealConfig | undefined,
  defaults: NormalizedTrayRevealConfig,
): NormalizedTrayRevealConfig {
  const context = widgetContext(id, "reveal")
  const rawReveal = normalizeObjectConfig(context, reveal)

  return {
    durationMs: normalizePositiveNumber(
      childContext(context, "durationMs"),
      rawReveal?.durationMs,
      defaults.durationMs,
    ),
  }
}
