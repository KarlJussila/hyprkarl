import type {
  FlyoutAlign,
  FlyoutConfig,
  NormalizedFlyoutConfig,
} from "./flyoutTypes.ts"
import {
  childContext,
  fail,
  normalizeBoolean,
  normalizeNonNegativeNumber,
  normalizeObjectConfig,
  type ValidationContext,
} from "./normalize.ts"

export function normalizeFlyoutAlign(
  context: ValidationContext,
  value: FlyoutAlign | undefined,
  fallback: FlyoutAlign,
): FlyoutAlign {
  const align = value ?? fallback
  if (align !== "start" && align !== "center" && align !== "end") {
    fail(context, 'must be "start", "center", or "end"')
  }
  return align
}

export function normalizeFlyoutConfig(
  ctx: ValidationContext,
  config: FlyoutConfig | undefined,
  defaults: NormalizedFlyoutConfig,
): NormalizedFlyoutConfig {
  const rawConfig = normalizeObjectConfig(ctx, config) as FlyoutConfig | undefined

  return {
    enabled: normalizeBoolean(childContext(ctx, "enabled"), rawConfig?.enabled, defaults.enabled),
    align: normalizeFlyoutAlign(childContext(ctx, "align"), rawConfig?.align, defaults.align),
    gap: normalizeNonNegativeNumber(childContext(ctx, "gap"), rawConfig?.gap, defaults.gap),
  }
}
