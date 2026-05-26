import assert from "node:assert/strict"
import test from "node:test"
import { formatBatteryTooltip } from "../../widgets/battery/batteryTooltip.ts"
import type { ResolvedBarWidgetDefinition } from "../../widgets/catalog.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedBatteryWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "battery" }>

test("normalizes battery widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["battery"],
      center: {
        start: [],
        center: [],
        end: [],
      },
      end: [],
    },
    {
      battery: { kind: "battery" },
    },
  )

  const battery = resolved.widgets.battery as ResolvedBatteryWidgetConfig
  assert.equal(battery.showPercentage, true)
  assert.equal(battery.lowThreshold, 0.15)
  assert.equal(battery.flyout.enabled, true)
  assert.equal(battery.tooltip.charging, "{power}↑ {time}")
  assert.equal(battery.tooltip.fallback, "{percentage}")
  assert.equal(battery.indicator.terminalHeight, 4)
  assert.equal(battery.indicator.chargingGlyph, "󱐋")
})

test("normalizes flat widget appearance overrides", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["caffeine"],
      center: {
        start: [],
        center: ["clock"],
        end: [],
      },
      end: ["battery"],
    },
    {
      caffeine: {
        kind: "caffeine",
        switch: {
          trackLength: 32,
          glyphOffsetY: -1,
        },
      },
      clock: {
        kind: "clock",
      },
      battery: {
        kind: "battery",
        indicator: {
          width: 20,
          terminalWidth: 5,
          terminalHeight: 2,
          chargingGlyphFontSize: 10,
        },
      },
    },
  )

  const battery = resolved.widgets.battery as ResolvedBatteryWidgetConfig
  assert.equal(battery.indicator.width, 20)
  assert.equal(battery.indicator.terminalWidth, 5)
  assert.equal(battery.indicator.terminalHeight, 2)
  assert.equal(battery.indicator.chargingGlyphFontSize, 10)
})

test("normalizes battery tooltip format overrides", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["battery"],
      center: {
        start: [],
        center: [],
        end: [],
      },
      end: [],
    },
    {
      battery: {
        kind: "battery",
        tooltip: {
          charging: "{percentage} charging at {power}",
          fallback: "Battery {percentage}",
        },
      },
    },
  )

  const battery = resolved.widgets.battery as ResolvedBatteryWidgetConfig
  assert.equal(battery.tooltip.charging, "{percentage} charging at {power}")
  assert.equal(battery.tooltip.discharging, "{power}↓ {time}")
  assert.equal(battery.tooltip.fallback, "Battery {percentage}")
})

test("formats a charging battery tooltip with power and time tokens", () => {
  assert.equal(
    formatBatteryTooltip({
      percentage: 0.67,
      charging: true,
      energyRate: -45.23,
      timeToEmpty: 0,
      timeToFull: 5430,
      formats: {
        enabled: true,
        charging: "{power}↑ {time} {percentage}",
        discharging: "{power}↓ {time} {percentage}",
        plugged: "Plugged in {percentage}",
        fallback: "{percentage}",
      },
    }),
    "45.2W↑ 1:31 67%",
  )
})

test("formats a discharging battery tooltip with power and time tokens", () => {
  assert.equal(
    formatBatteryTooltip({
      percentage: 0.42,
      charging: false,
      energyRate: 17.04,
      timeToEmpty: 7210,
      timeToFull: 0,
      formats: {
        enabled: true,
        charging: "{power}↑ {time} {percentage}",
        discharging: "{power}↓ {time} {percentage}",
        plugged: "Plugged in {percentage}",
        fallback: "{percentage}",
      },
    }),
    "17.0W↓ 2:00 42%",
  )
})

test("falls back cleanly when battery rate is unavailable", () => {
  assert.equal(
    formatBatteryTooltip({
      percentage: 1,
      charging: true,
      energyRate: 0,
      timeToEmpty: 0,
      timeToFull: 0,
      formats: {
        enabled: true,
        charging: "{power}↑ {time} {percentage}",
        discharging: "{power}↓ {time} {percentage}",
        plugged: "Plugged in {percentage}",
        fallback: "{percentage}",
      },
    }),
    "Plugged in 100%",
  )
  assert.equal(
    formatBatteryTooltip({
      percentage: 0.58,
      charging: false,
      energyRate: 0,
      timeToEmpty: 0,
      timeToFull: 0,
      formats: {
        enabled: true,
        charging: "{power}↑ {time} {percentage}",
        discharging: "{power}↓ {time} {percentage}",
        plugged: "Plugged in {percentage}",
        fallback: "{percentage}",
      },
    }),
    "57%",
  )
})

test("collapses empty battery tooltip tokens cleanly", () => {
  assert.equal(
    formatBatteryTooltip({
      percentage: 0.51,
      charging: false,
      energyRate: 11.6,
      timeToEmpty: 0,
      timeToFull: 0,
      formats: {
        charging: "{power}↑ {time} {percentage}",
        discharging: "{power} {time} {percentage}",
        plugged: "Plugged in {percentage}",
        fallback: "{percentage}",
      },
    }),
    "11.6W 51%",
  )
})
