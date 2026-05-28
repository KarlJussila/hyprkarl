import assert from "node:assert/strict"
import test from "node:test"
import type { ResolvedBarWidgetDefinition } from "../../widgets/catalog.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedToggleWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "toggle" }>

test("normalizes toggle widget defaults to neutral placeholders", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["caffeine"], center: { start: [], center: [], end: [] }, end: [] },
    { caffeine: { kind: "toggle" } },
  )

  const toggle = resolved.widgets.caffeine as ResolvedToggleWidgetConfig
  assert.equal(toggle.switch.glyphs.on.glyph, "?")
  assert.equal(toggle.switch.glyphs.off.glyph, "?")
  assert.equal(toggle.commands.on, "true")
  assert.equal(toggle.commands.off, "true")
  assert.equal(toggle.commands.sync, "false")
  assert.equal(toggle.endpoint, "")
  assert.equal(toggle.switch.trackLength, 24)
  assert.equal(toggle.tooltip.active, "")
  assert.equal(toggle.tooltip.inactive, "")
})

test("normalizes toggle advanced switch overrides", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["caffeine"], center: { start: [], center: [], end: [] }, end: [] },
    {
      caffeine: {
        kind: "toggle",
        switch: {
          trackLength: 32,
          glyphs: {
            on: { glyphOffset: [0, -1] },
          },
        },
      },
    },
  )

  const toggle = resolved.widgets.caffeine as ResolvedToggleWidgetConfig
  assert.equal(toggle.switch.trackLength, 32)
  assert.equal(toggle.switch.glyphs.on.glyphOffset[1], -1)
})

test("allows toggle widgets to override commands, endpoint, and tooltip text", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["caffeine"], center: { start: [], center: [], end: [] }, end: [] },
    {
      caffeine: {
        kind: "toggle",
        commands: {
          on: "hk-caffeine on",
          off: "hk-caffeine off",
          sync: "hk-caffeine status",
        },
        endpoint: "caffeine-sync",
        tooltip: { active: "No sleep", inactive: "Sleep allowed" },
      },
    },
  )

  const toggle = resolved.widgets.caffeine as ResolvedToggleWidgetConfig
  assert.equal(toggle.commands.on, "hk-caffeine on")
  assert.equal(toggle.endpoint, "caffeine-sync")
  assert.equal(toggle.tooltip.active, "No sleep")
  assert.equal(toggle.tooltip.inactive, "Sleep allowed")
})
