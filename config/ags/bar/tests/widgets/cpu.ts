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
  assert.equal(cpu.icon, "󰍛")
  assert.equal(cpu.format, "")
  assert.equal(cpu.interval, 2000)
})

test("normalizes cpu widget config overrides", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["cpu"], center: { start: [], end: [] }, end: [] },
    {
      cpu: {
        kind: "cpu",
        icon: "󰻠",
        format: "{usage}",
        interval: 1000,
      },
    },
  )

  const cpu = resolved.widgets.cpu as ResolvedCpuWidgetConfig
  assert.equal(cpu.icon, "󰻠")
  assert.equal(cpu.format, "{usage}")
  assert.equal(cpu.interval, 1000)
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
