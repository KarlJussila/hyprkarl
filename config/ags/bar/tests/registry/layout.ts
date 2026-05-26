import assert from "node:assert/strict"
import test from "node:test"
import {
  BAR_LAYOUT_SOURCE_FILE,
  BAR_WIDGETS_SOURCE_FILE,
  formatBarConfigError,
} from "../../configError.ts"
import type { BarLayoutConfig } from "../../configuration.ts"
import { expectBarConfigError, resolveBarConfiguration } from "../support/index.ts"
import type { BarWidgetDefinitions } from "../../widgets/catalog.ts"

test("layout defaults decorative corner curves to enabled", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "right",
      start: ["menu", "workspaces", "tray"],
      center: {
        start: [],
        center: ["clock"],
        end: ["caffeine"],
      },
      end: ["battery"],
    },
    {
      menu: { kind: "menu" },
      workspaces: { kind: "workspaces" },
      tray: { kind: "tray" },
      clock: { kind: "clock" },
      caffeine: { kind: "caffeine" },
      battery: { kind: "battery" },
    },
  )

  assert.equal(resolved.edge, "right")
  assert.equal(resolved.showCornerCurves, true)
})

test("allows layout config to disable decorative corner curves independently", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      showCornerCurves: false,
      start: ["menu"],
      center: {
        start: [],
        center: ["clock"],
        end: [],
      },
      end: [],
    },
    {
      menu: { kind: "menu" },
      clock: { kind: "clock" },
    },
  )

  assert.equal(resolved.showCornerCurves, false)
})

test("rejects invalid layout-level corner curve toggle values", () => {
  const layout = {
    edge: "top",
    showCornerCurves: "sometimes",
    start: ["menu"],
    center: {
      start: [],
      center: ["clock"],
      end: [],
    },
    end: [],
  } as unknown as BarLayoutConfig

  const error = expectBarConfigError(() => resolveBarConfiguration(layout, {
    menu: { kind: "menu" },
    clock: { kind: "clock" },
  }))

  assert.equal(error.sourceFile, BAR_LAYOUT_SOURCE_FILE)
  assert.equal(error.path, "showCornerCurves")
  assert.equal(error.message, "must be true or false")
  assert.equal(
    formatBarConfigError(error),
    "Bar config error in layout.config.ts at showCornerCurves: must be true or false",
  )
})

test("rejects missing widget references in the layout", () => {
  const error = expectBarConfigError(() => resolveBarConfiguration(
    {
      edge: "top",
      start: ["menu"],
      center: {
        start: [],
        center: ["clock"],
        end: [],
      },
      end: ["battery"],
    },
    {
      menu: { kind: "menu" },
      clock: { kind: "clock" },
    },
  ))

  assert.equal(error.sourceFile, BAR_LAYOUT_SOURCE_FILE)
  assert.equal(error.path, "end[0]")
  assert.equal(error.message, 'references unknown widget ID "battery"')
  assert.equal(
    formatBarConfigError(error),
    'Bar config error in layout.config.ts at end[0]: references unknown widget ID "battery"',
  )
})

test("allows the same widget ID to appear more than once in the layout", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["menu"],
      center: {
        start: [],
        center: ["clock"],
        end: ["menu"],
      },
      end: [],
    },
    {
      menu: { kind: "menu" },
      clock: { kind: "clock" },
    },
  )

  assert.deepEqual(resolved.layout.start, ["menu"])
  assert.deepEqual(resolved.layout.center.end, ["menu"])
})

test("allows an empty center island without any center widgets", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["menu"],
      center: {
        start: [],
        center: [],
        end: [],
      },
      end: ["battery"],
    },
    {
      menu: { kind: "menu" },
      battery: { kind: "battery" },
    },
  )

  assert.deepEqual(resolved.layout.center.center, [])
  assert.deepEqual(resolved.layout.center.start, [])
  assert.deepEqual(resolved.layout.center.end, [])
})

test("allows multiple widgets in the center array", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["menu"],
      center: {
        start: [],
        center: ["clock", "caffeine"],
        end: [],
      },
      end: [],
    },
    {
      menu: { kind: "menu" },
      clock: { kind: "clock" },
      caffeine: { kind: "caffeine" },
    },
  )

  assert.deepEqual(resolved.layout.center.center, ["clock", "caffeine"])
})

test("rejects center.start or center.end widgets without center.center items", () => {
  const error = expectBarConfigError(() => resolveBarConfiguration(
    {
      edge: "top",
      start: ["menu"],
      center: {
        start: ["clock"],
        center: [],
        end: [],
      },
      end: [],
    },
    {
      menu: { kind: "menu" },
      clock: { kind: "clock" },
    },
  ))

  assert.equal(error.sourceFile, BAR_LAYOUT_SOURCE_FILE)
  assert.equal(error.path, "center.center")
})

test("rejects unknown widget kinds at normalization time", () => {
  const error = expectBarConfigError(() => resolveBarConfiguration(
    {
      edge: "top",
      start: ["mystery"],
      center: {
        start: [],
        center: ["clock"],
        end: [],
      },
      end: [],
    },
    {
      mystery: { kind: "mystery" },
      clock: { kind: "clock" },
    } as unknown as BarWidgetDefinitions,
  ))

  assert.equal(error.sourceFile, BAR_WIDGETS_SOURCE_FILE)
  assert.equal(error.widgetId, "mystery")
  assert.equal(error.path, "mystery.kind")
  assert.equal(error.message, 'unknown widget kind "mystery"')
  assert.equal(
    formatBarConfigError(error),
    'Bar config error in widgets.config.ts at mystery.kind: unknown widget kind "mystery"',
  )
})
