import assert from "node:assert/strict"
import test from "node:test"
import type { ResolvedBarWidgetDefinition } from "../../widgets/catalog.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedClockWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "clock" }>

test("normalizes clock widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["clock"], center: { start: [], end: [] }, end: [] },
    { clock: { kind: "clock" } },
  )

  const clock = resolved.widgets.clock as ResolvedClockWidgetConfig
  assert.equal(clock.format, "%a %-I:%M %p")
  assert.equal(clock.formatAlt, "")
  assert.equal(clock.formatVertical, "%I\n%M\n%p")
  assert.equal(clock.formatVerticalAlt, "")
  assert.equal(clock.flyout.enabled, true)
  assert.equal(clock.flyout.align, "center")
  assert.equal(clock.flyout.gap, 0)
})

test("normalizes clock widget overrides", () => {
  const resolved = resolveBarConfiguration(
    { edge: "left", start: ["clock"], center: { start: [], end: [] }, end: [] },
    {
      clock: {
        kind: "clock",
        format: "%H:%M",
        formatVertical: "%H\n%M",
        flyout: { enabled: false },
      },
    },
  )

  const clock = resolved.widgets.clock as ResolvedClockWidgetConfig
  assert.equal(clock.format, "%H:%M")
  assert.equal(clock.formatVertical, "%H\n%M")
  assert.equal(clock.flyout.enabled, false)
})
