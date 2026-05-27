import type { TrayDirection } from "./types.ts"
import { fail, type ValidationContext } from "../shared/normalize.ts"

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
