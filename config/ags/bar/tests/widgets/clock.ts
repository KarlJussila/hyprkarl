import assert from "node:assert/strict"
import test from "node:test"
import type { NormalizedClockWidgetConfig } from "../../configuration.ts"
import { resolveBarConfiguration } from "../support/index.ts"

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

  const clock = resolved.widgets.clock as NormalizedClockWidgetConfig
  assert.equal(clock.display.horizontal, "%a %-I:%M %p")
  assert.deepEqual(clock.display.vertical, {
    top: "%I",
    middle: "%M",
    bottom: "%p",
  })
  assert.equal(clock.dropdown.enabled, true)
  assert.equal(clock.dropdown.align, "center")
  assert.equal(clock.dropdown.gap, 0)
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
        dropdown: {
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

  const clock = resolved.widgets.clock as NormalizedClockWidgetConfig
  assert.equal(clock.dropdown.enabled, false)
  assert.deepEqual(clock.display.vertical, {
    top: "%H",
    middle: "%M",
    bottom: "%p",
  })
})
