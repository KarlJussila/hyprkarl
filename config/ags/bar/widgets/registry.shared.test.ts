import assert from "node:assert/strict"
import test from "node:test"
import {
  BAR_LAYOUT_SOURCE_FILE,
  BAR_WIDGETS_SOURCE_FILE,
  BarConfigError,
  formatBarConfigError,
} from "../configError.ts"
import type {
  BarLayoutConfig,
  BarWidgetDefinitions,
  NormalizedBatteryWidgetConfig,
  NormalizedClockWidgetConfig,
  NormalizedMenuWidgetConfig,
  NormalizedTrayWidgetConfig,
  NormalizedWorkspacesWidgetConfig,
} from "../configuration.ts"
import { normalizeBarConfiguration } from "./registry.shared.ts"

function expectBarConfigError(callback: () => void): BarConfigError {
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

test("normalizes built-in widget defaults from data-only config", () => {
  const layout = {
    edge: "right",
    start: ["menu", "workspaces", "tray"],
    center: {
      start: [],
      anchor: "clock",
      end: ["caffeine"],
    },
    end: ["battery"],
  } satisfies BarLayoutConfig

  const widgets = {
    menu: { kind: "menu" },
    workspaces: { kind: "workspaces" },
    tray: { kind: "tray" },
    clock: { kind: "clock" },
    caffeine: { kind: "caffeine" },
    battery: { kind: "battery" },
  } satisfies BarWidgetDefinitions

  const resolved = normalizeBarConfiguration(layout, widgets)
  const menu = resolved.widgets.menu as NormalizedMenuWidgetConfig
  const workspaces = resolved.widgets.workspaces as NormalizedWorkspacesWidgetConfig
  const tray = resolved.widgets.tray as NormalizedTrayWidgetConfig
  const clock = resolved.widgets.clock as NormalizedClockWidgetConfig
  const battery = resolved.widgets.battery as NormalizedBatteryWidgetConfig

  assert.equal(resolved.edge, "right")
  assert.equal(menu.icon, "")
  assert.equal(menu.commands.primary, "hyprkarl-menu")
  assert.equal(workspaces.mode, "dynamic")
  if (workspaces.mode !== "dynamic") {
    throw new Error("expected dynamic workspaces config")
  }
  assert.deepEqual(workspaces.visibility.alwaysShow, [1])
  assert.equal(tray.direction, "start")
  assert.equal(tray.reveal.durationMs, 220)
  assert.equal(clock.display.horizontal, "%a %-I:%M %p")
  assert.deepEqual(clock.display.vertical, {
    top: "%I",
    middle: "%M",
    bottom: "%p",
  })
  assert.equal(battery.lowThreshold, 0.15)
  assert.equal(battery.indicator.chargingGlyph, "󱐋")
})

test("rejects missing widget references in the layout", () => {
  const layout = {
    edge: "top",
    start: ["menu"],
    center: {
      start: [],
      anchor: "clock",
      end: [],
    },
    end: ["battery"],
  } satisfies BarLayoutConfig

  const widgets = {
    menu: { kind: "menu" },
    clock: { kind: "clock" },
  } satisfies BarWidgetDefinitions

  const error = expectBarConfigError(() => normalizeBarConfiguration(layout, widgets))

  assert.equal(error.sourceFile, BAR_LAYOUT_SOURCE_FILE)
  assert.equal(error.path, "end[0]")
  assert.equal(error.message, 'references unknown widget ID "battery"')
  assert.equal(
    formatBarConfigError(error),
    'Bar config error in layout.config.ts at end[0]: references unknown widget ID "battery"',
  )
})

test("rejects duplicate widget IDs in the layout", () => {
  const layout = {
    edge: "top",
    start: ["menu"],
    center: {
      start: [],
      anchor: "clock",
      end: ["menu"],
    },
    end: [],
  } satisfies BarLayoutConfig

  const widgets = {
    menu: { kind: "menu" },
    clock: { kind: "clock" },
  } satisfies BarWidgetDefinitions

  const error = expectBarConfigError(() => normalizeBarConfiguration(layout, widgets))

  assert.equal(error.sourceFile, BAR_LAYOUT_SOURCE_FILE)
  assert.equal(error.path, "center.end[0]")
  assert.equal(error.message, 'widget ID "menu" is used more than once in the layout')
  assert.equal(
    formatBarConfigError(error),
    'Bar config error in layout.config.ts at center.end[0]: widget ID "menu" is used more than once in the layout',
  )
})

test("rejects unknown widget kinds at normalization time", () => {
  const layout = {
    edge: "top",
    start: ["mystery"],
    center: {
      start: [],
      anchor: "clock",
      end: [],
    },
    end: [],
  } satisfies BarLayoutConfig

  const widgets = {
    mystery: { kind: "mystery" },
    clock: { kind: "clock" },
  } as unknown as BarWidgetDefinitions

  const error = expectBarConfigError(() => normalizeBarConfiguration(layout, widgets))

  assert.equal(error.sourceFile, BAR_WIDGETS_SOURCE_FILE)
  assert.equal(error.widgetId, "mystery")
  assert.equal(error.path, "mystery.kind")
  assert.equal(error.message, 'unknown widget kind "mystery"')
  assert.equal(
    formatBarConfigError(error),
    'Bar config error in widgets.config.ts at mystery.kind: unknown widget kind "mystery"',
  )
})

test("normalizes fixed workspaces and widget-specific overrides", () => {
  const layout = {
    edge: "left",
    start: ["workspaces"],
    center: {
      start: [],
      anchor: "clock",
      end: [],
    },
    end: [],
  } satisfies BarLayoutConfig

  const widgets = {
    workspaces: {
      kind: "workspaces",
      mode: "fixed",
      ids: [3, 1, 3],
    },
    clock: {
      kind: "clock",
      dropdown: {
        enabled: false,
      },
      display: {
        vertical: {
          top: "%H",
        },
      },
    },
  } satisfies BarWidgetDefinitions

  const resolved = normalizeBarConfiguration(layout, widgets)
  const workspaces = resolved.widgets.workspaces as NormalizedWorkspacesWidgetConfig
  const clock = resolved.widgets.clock as NormalizedClockWidgetConfig

  assert.equal(workspaces.mode, "fixed")
  if (workspaces.mode !== "fixed") {
    throw new Error("expected fixed workspaces config")
  }
  assert.deepEqual(workspaces.ids, [3, 1])
  assert.equal(clock.dropdown.enabled, false)
  assert.deepEqual(clock.display.vertical, {
    top: "%H",
    middle: "%M",
    bottom: "%p",
  })
})

test("rejects invalid widget option values with widget metadata", () => {
  const layout = {
    edge: "top",
    start: ["battery"],
    center: {
      start: [],
      anchor: "clock",
      end: [],
    },
    end: [],
  } satisfies BarLayoutConfig

  const widgets = {
    battery: {
      kind: "battery",
      lowThreshold: -0.1,
    },
    clock: {
      kind: "clock",
    },
  } satisfies BarWidgetDefinitions

  const error = expectBarConfigError(() => normalizeBarConfiguration(layout, widgets))

  assert.equal(error.sourceFile, BAR_WIDGETS_SOURCE_FILE)
  assert.equal(error.widgetId, "battery")
  assert.equal(error.path, "battery.lowThreshold")
  assert.equal(error.message, "must be between 0 and 1")
  assert.equal(
    formatBarConfigError(error),
    "Bar config error in widgets.config.ts at battery.lowThreshold: must be between 0 and 1",
  )
})
