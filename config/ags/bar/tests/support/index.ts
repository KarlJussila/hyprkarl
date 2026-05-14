import assert from "node:assert/strict"
import type { BarLayoutConfig, BarWidgetDefinitions } from "../../configuration.ts"
import { BarConfigError } from "../../configError.ts"
import { normalizeBarConfiguration } from "../../widgets/registry.shared.ts"

export function expectBarConfigError(callback: () => void): BarConfigError {
  try {
    callback()
    assert.fail("expected a BarConfigError")
  } catch (error) {
    if (error instanceof BarConfigError) {
      return error
    }

    throw error
  }
}

export function resolveBarConfiguration(
  layout: BarLayoutConfig,
  widgets: BarWidgetDefinitions,
) {
  return normalizeBarConfiguration(layout, widgets)
}
