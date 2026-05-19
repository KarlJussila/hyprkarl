import assert from "node:assert/strict"
import test from "node:test"
import type { ResolvedBarWidgetDefinition } from "../../widgets/catalog.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedCaffeineWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "caffeine" }>

test("normalizes caffeine widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["caffeine"],
      center: {
        start: [],
        end: [],
      },
      end: [],
    },
    {
      caffeine: { kind: "caffeine" },
    },
  )

  const caffeine = resolved.widgets.caffeine as ResolvedCaffeineWidgetConfig
  assert.equal(caffeine.glyph, "")
  assert.equal(caffeine.command, "hk-caffeine")
  assert.equal(caffeine.switch.trackLength, 24)
})

test("normalizes caffeine advanced switch overrides", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["caffeine"],
      center: {
        start: [],
        end: [],
      },
      end: [],
    },
    {
      caffeine: {
        kind: "caffeine",
        switch: {
          trackLength: 32,
          glyphOffsetY: -1,
        },
      },
    },
  )

  const caffeine = resolved.widgets.caffeine as ResolvedCaffeineWidgetConfig
  assert.equal(caffeine.switch.trackLength, 32)
  assert.equal(caffeine.switch.glyphOffsetY, -1)
})
