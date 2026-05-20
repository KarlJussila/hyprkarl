import assert from "node:assert/strict"
import test from "node:test"
import type { ResolvedBarWidgetDefinition } from "../../widgets/catalog.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedCpuWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "cpu" }>

test("normalizes cpu widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["cpu"], center: { start: [], end: [] }, end: [] },
    { cpu: { kind: "cpu" } },
  )

  const cpu = resolved.widgets.cpu as ResolvedCpuWidgetConfig
  assert.equal(cpu.icon, "󰘚")
  assert.equal(cpu.showPercentage, false)
  assert.equal(cpu.interval, 2000)
  assert.equal(cpu.warningThreshold, 0.75)
})

test("normalizes cpu widget config overrides", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["cpu"], center: { start: [], end: [] }, end: [] },
    {
      cpu: {
        kind: "cpu",
        icon: "󰻠",
        showPercentage: false,
        interval: 1000,
        warningThreshold: 0.9,
      },
    },
  )

  const cpu = resolved.widgets.cpu as ResolvedCpuWidgetConfig
  assert.equal(cpu.icon, "󰻠")
  assert.equal(cpu.showPercentage, false)
  assert.equal(cpu.interval, 1000)
  assert.equal(cpu.warningThreshold, 0.9)
})

test("rejects a non-positive interval", () => {
  assert.throws(
    () =>
      resolveBarConfiguration(
        { edge: "top", start: ["cpu"], center: { start: [], end: [] }, end: [] },
        { cpu: { kind: "cpu", interval: 0 } },
      ),
    { name: "BarConfigError" },
  )
})

test("rejects a warningThreshold outside 0-1", () => {
  assert.throws(
    () =>
      resolveBarConfiguration(
        { edge: "top", start: ["cpu"], center: { start: [], end: [] }, end: [] },
        { cpu: { kind: "cpu", warningThreshold: 1.5 } },
      ),
    { name: "BarConfigError" },
  )
})
