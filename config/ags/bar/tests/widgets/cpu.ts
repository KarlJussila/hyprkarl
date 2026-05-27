import assert from "node:assert/strict"
import test from "node:test"
import type { ResolvedBarWidgetDefinition } from "../../widgets/catalog.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedCpuWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "cpu" }>

test("normalizes cpu widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["cpu"], center: { start: [], center: [], end: [] }, end: [] },
    { cpu: { kind: "cpu" } },
  )

  const cpu = resolved.widgets.cpu as ResolvedCpuWidgetConfig
  assert.equal(cpu.icon, "󰍛")
  assert.equal(cpu.format.primary, "")
  assert.equal(cpu.format.alt, "")
  assert.equal(cpu.format.vertical, "")
  assert.equal(cpu.format.verticalAlt, "")
  assert.equal(cpu.decimals.primary, 0)
  assert.equal(cpu.decimals.alt, 0)
  assert.equal(cpu.decimals.vertical, 0)
  assert.equal(cpu.decimals.verticalAlt, 0)
  assert.equal(cpu.reveal.durationMs, 200)
  assert.equal(cpu.interval, 5000)
  assert.equal(cpu.commands.primary, undefined)
  assert.equal(cpu.commands.secondary, undefined)
  assert.equal(cpu.commands.tertiary, undefined)
})

test("allows cpu widget commands to be overridden", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["cpu"], center: { start: [], center: [], end: [] }, end: [] },
    {
      cpu: {
        kind: "cpu",
        commands: { primary: "{toggle-label}", secondary: "", tertiary: "htop" },
      },
    },
  )

  const cpu = resolved.widgets.cpu as ResolvedCpuWidgetConfig
  assert.equal(cpu.commands.primary, "{toggle-label}")
  assert.equal(cpu.commands.secondary, "")
  assert.equal(cpu.commands.tertiary, "htop")
})

test("normalizes cpu widget config overrides", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["cpu"], center: { start: [], center: [], end: [] }, end: [] },
    {
      cpu: {
        kind: "cpu",
        icon: "󰻠",
        format: { primary: "{usage}%", alt: "{temp}°", vertical: "{usage}%", verticalAlt: "{temp}°" },
        interval: 1000,
      },
    },
  )

  const cpu = resolved.widgets.cpu as ResolvedCpuWidgetConfig
  assert.equal(cpu.icon, "󰻠")
  assert.equal(cpu.format.primary, "{usage}%")
  assert.equal(cpu.format.alt, "{temp}°")
  assert.equal(cpu.format.vertical, "{usage}%")
  assert.equal(cpu.format.verticalAlt, "{temp}°")
  assert.equal(cpu.interval, 1000)
})

test("decimals cascade to all variants when not overridden", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["cpu"], center: { start: [], center: [], end: [] }, end: [] },
    { cpu: { kind: "cpu", decimals: { primary: 2 } } },
  )

  const cpu = resolved.widgets.cpu as ResolvedCpuWidgetConfig
  assert.equal(cpu.decimals.primary, 2)
  assert.equal(cpu.decimals.alt, 2)
  assert.equal(cpu.decimals.vertical, 2)
  assert.equal(cpu.decimals.verticalAlt, 2)
})

test("rejects a non-positive interval", () => {
  assert.throws(
    () =>
      resolveBarConfiguration(
        { edge: "top", start: ["cpu"], center: { start: [], center: [], end: [] }, end: [] },
        { cpu: { kind: "cpu", interval: 0 } },
      ),
    { name: "BarConfigError" },
  )
})
