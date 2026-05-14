import assert from "node:assert/strict"
import test from "node:test"
import type { NormalizedBatteryWidgetConfig } from "../../configuration.ts"
import { resolveBarConfiguration } from "../support/index.ts"

test("normalizes battery widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["battery"],
      center: {
        start: [],
        end: [],
      },
      end: [],
    },
    {
      battery: { kind: "battery" },
    },
  )

  const battery = resolved.widgets.battery as NormalizedBatteryWidgetConfig
  assert.equal(battery.showPercentage, true)
  assert.equal(battery.lowThreshold, 0.15)
  assert.equal(battery.dropdown.enabled, true)
  assert.equal(battery.indicator.chargingGlyph, "󱐋")
})

test("normalizes advanced widget appearance overrides behind nested config", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["caffeine"],
      center: {
        start: [],
        anchor: "clock",
        end: [],
      },
      end: ["battery"],
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
      clock: {
        kind: "clock",
      },
      battery: {
        kind: "battery",
        advanced: {
          indicator: {
            width: 20,
            chargingGlyphFontSize: 10,
          },
        },
      },
    },
  )

  const battery = resolved.widgets.battery as NormalizedBatteryWidgetConfig
  assert.equal(battery.indicator.width, 20)
  assert.equal(battery.indicator.chargingGlyphFontSize, 10)
})
