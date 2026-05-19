import assert from "node:assert/strict"
import test from "node:test"
import type { ResolvedBarWidgetDefinition } from "../../widgets/catalog.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedClockWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "clock" }>

test("normalizes clock widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["clock"],
      center: {
        start: [],
        end: [],
      },
      end: [],
    },
    {
      clock: { kind: "clock" },
    },
  )

  const clock = resolved.widgets.clock as ResolvedClockWidgetConfig
  assert.equal(clock.display.horizontal, "%a %-I:%M %p")
  assert.deepEqual(clock.display.vertical, {
    top: "%I",
    middle: "%M",
    bottom: "%p",
  })
  assert.equal(clock.flyout.enabled, true)
  assert.equal(clock.flyout.align, "center")
  assert.equal(clock.flyout.gap, 0)
})

test("normalizes clock widget overrides", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "left",
      start: ["clock"],
      center: {
        start: [],
        end: [],
      },
      end: [],
    },
    {
      clock: {
        kind: "clock",
        flyout: {
          enabled: false,
        },
        display: {
          vertical: {
            top: "%H",
          },
        },
      },
    },
  )

  const clock = resolved.widgets.clock as ResolvedClockWidgetConfig
  assert.equal(clock.flyout.enabled, false)
  assert.deepEqual(clock.display.vertical, {
    top: "%H",
    middle: "%M",
    bottom: "%p",
  })
})
