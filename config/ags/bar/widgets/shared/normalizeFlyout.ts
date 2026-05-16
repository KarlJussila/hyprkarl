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
  widgetContext,
  type ValidationContext,
} from "./normalize.ts"

export function normalizeFlyoutAlign(
  context: ValidationContext,
  value: unknown,
  fallback: FlyoutAlign,
) {
  const align = value ?? fallback
  if (align !== "start" && align !== "center" && align !== "end") {
    fail(context, 'must be "start", "center", or "end"')
  }

  return align
}

export function normalizeFlyoutConfig(
  id: string,
  config: FlyoutConfig | undefined,
  defaults: NormalizedFlyoutConfig,
): NormalizedFlyoutConfig {
  const context = widgetContext(id, "flyout")
  const rawConfig = normalizeObjectConfig(context, config)

  return {
    enabled: normalizeBoolean(
      childContext(context, "enabled"),
      rawConfig?.enabled,
      defaults.enabled,
    ),
    align: normalizeFlyoutAlign(
      childContext(context, "align"),
      rawConfig?.align,
      defaults.align,
    ),
    gap: normalizeNonNegativeNumber(
      childContext(context, "gap"),
      rawConfig?.gap,
      defaults.gap,
    ),
  }
}
