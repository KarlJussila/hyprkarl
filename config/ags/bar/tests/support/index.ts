import assert from "node:assert/strict"
import type { BarLayoutConfig } from "../../configuration.ts"
import { BarConfigError } from "../../configError.ts"
import { resolveBarConfiguration as resolveRuntimeBarConfiguration } from "../../widgets/resolveBarConfiguration.ts"
import type { BarWidgetDefinitions } from "../../widgets/catalog.ts"

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
  return resolveRuntimeBarConfiguration(layout, widgets)
}
