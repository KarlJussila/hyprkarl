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
  type ValidationContext,
} from "../shared/normalize.ts"

export function normalizeTrayDirection(
  ctx: ValidationContext,
  value: TrayDirection | undefined,
  fallback: TrayDirection,
): TrayDirection {
  const direction = value ?? fallback
  if (direction !== "start" && direction !== "end") {
    fail(ctx, 'must be "start" or "end"')
  }
  return direction
}

export function normalizeRevealConfig(
  ctx: ValidationContext,
  reveal: TrayRevealConfig | undefined,
  defaults: NormalizedTrayRevealConfig,
): NormalizedTrayRevealConfig {
  const rawReveal = normalizeObjectConfig(ctx, reveal) as TrayRevealConfig | undefined

  return {
    durationMs: normalizePositiveNumber(childContext(ctx, "durationMs"), rawReveal?.durationMs, defaults.durationMs),
  }
}
