import assert from "node:assert/strict"
import test from "node:test"
import type { NormalizedCaffeineWidgetConfig } from "../../configuration.ts"
import { resolveBarConfiguration } from "../support/index.ts"

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

  const caffeine = resolved.widgets.caffeine as NormalizedCaffeineWidgetConfig
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
        advanced: {
          switch: {
            trackLength: 32,
            glyphOffsetY: -1,
          },
        },
      },
    },
  )

  const caffeine = resolved.widgets.caffeine as NormalizedCaffeineWidgetConfig
  assert.equal(caffeine.switch.trackLength, 32)
  assert.equal(caffeine.switch.glyphOffsetY, -1)
})
