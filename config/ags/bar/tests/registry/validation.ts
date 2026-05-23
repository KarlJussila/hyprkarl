import assert from "node:assert/strict"
import test from "node:test"
import {
  BAR_WIDGETS_SOURCE_FILE,
  formatBarConfigError,
} from "../../configError.ts"
import type { BarLayoutConfig } from "../../configuration.ts"
import { expectBarConfigError, resolveBarConfiguration } from "../support/index.ts"
import type { BarWidgetDefinitions } from "../../widgets/catalog.ts"

test("rejects invalid widget option values with widget metadata", () => {
  const layout = {
    edge: "top",
    start: ["menu"],
    center: {
      start: [],
      end: [],
    },
    end: [],
  } satisfies BarLayoutConfig

  const widgets = {
    menu: {
      kind: "menu",
      commands: {
        primary: "",
      },
    },
  } satisfies BarWidgetDefinitions

  const error = expectBarConfigError(() => resolveBarConfiguration(layout, widgets))

  assert.equal(error.sourceFile, BAR_WIDGETS_SOURCE_FILE)
  assert.equal(error.widgetId, "menu")
  assert.equal(error.path, "menu.commands.primary")
  assert.equal(error.message, "must be a non-empty command")
  assert.equal(
    formatBarConfigError(error),
    "Bar config error in widgets.config.ts at menu.commands.primary: must be a non-empty command",
  )
})
