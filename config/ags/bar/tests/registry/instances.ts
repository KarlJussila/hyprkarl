import assert from "node:assert/strict"
import test from "node:test"
import type { BarLayoutConfig } from "../../configuration.ts"
import { resolveBarConfiguration } from "../support/index.ts"
import type {
  BarWidgetDefinitions,
  ResolvedBarWidgetDefinition,
} from "../../widgets/widgetTypes.ts"

type ResolvedClockWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "clock" }>

test("allows multiple widget IDs of the same kind with independent configs", () => {
  const layout = {
    edge: "top",
    start: ["clockCompact"],
    center: {
      start: [],
      anchor: "clockFull",
      end: [],
    },
    end: [],
  } satisfies BarLayoutConfig

  const widgets = {
    clockCompact: {
      kind: "clock",
      display: {
        horizontal: "%H:%M",
      },
      flyout: {
        enabled: false,
      },
    },
    clockFull: {
      kind: "clock",
      display: {
        horizontal: "%a %-I:%M %p",
      },
      flyout: {
        enabled: true,
        align: "end",
      },
    },
  } satisfies BarWidgetDefinitions

  const resolved = resolveBarConfiguration(layout, widgets)
  const compactClock = resolved.widgets.clockCompact as ResolvedClockWidgetConfig
  const fullClock = resolved.widgets.clockFull as ResolvedClockWidgetConfig

  assert.equal(compactClock.kind, "clock")
  assert.equal(fullClock.kind, "clock")
  assert.equal(compactClock.display.horizontal, "%H:%M")
  assert.equal(fullClock.display.horizontal, "%a %-I:%M %p")
  assert.equal(compactClock.flyout.enabled, false)
  assert.equal(fullClock.flyout.enabled, true)
  assert.equal(fullClock.flyout.align, "end")
})
