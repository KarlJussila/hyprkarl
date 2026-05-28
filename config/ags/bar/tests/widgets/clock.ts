import assert from "node:assert/strict"
import test from "node:test"
import type { ResolvedBarWidgetDefinition } from "../../widgets/catalog.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedClockWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "clock" }>

test("normalizes clock widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["clock"], center: { start: [], center: [], end: [] }, end: [] },
    { clock: { kind: "clock" } },
  )

  const clock = resolved.widgets.clock as ResolvedClockWidgetConfig
  assert.equal(clock.format.primary, "%a %-I:%M %p")
  assert.equal(clock.format.alt, "")
  assert.equal(clock.format.vertical, "%I\n%M\n%p")
  assert.equal(clock.format.verticalAlt, "")
  assert.equal(clock.flyout.align, "center")
  assert.equal(clock.flyout.gap, 0)
})

test("normalizes clock widget overrides", () => {
  const resolved = resolveBarConfiguration(
    { edge: "left", start: ["clock"], center: { start: [], center: [], end: [] }, end: [] },
    {
      clock: {
        kind: "clock",
        format: { primary: "%H:%M", vertical: "%H\n%M" },
        flyout: { align: "start" },
      },
    },
  )

  const clock = resolved.widgets.clock as ResolvedClockWidgetConfig
  assert.equal(clock.format.primary, "%H:%M")
  assert.equal(clock.format.vertical, "%H\n%M")
  assert.equal(clock.flyout.align, "start")
})
