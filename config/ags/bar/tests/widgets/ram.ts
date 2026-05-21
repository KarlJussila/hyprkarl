import assert from "node:assert/strict"
import test from "node:test"
import type { ResolvedBarWidgetDefinition } from "../../widgets/catalog.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedRamWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "ram" }>

test("normalizes ram widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["ram"], center: { start: [], end: [] }, end: [] },
    { ram: { kind: "ram" } },
  )

  const ram = resolved.widgets.ram as ResolvedRamWidgetConfig
  assert.equal(ram.decimals, 0)
  assert.equal(ram.decimalsAlt, 0)
  assert.equal(ram.decimalsVertical, 0)
  assert.equal(ram.decimalsVerticalAlt, 0)
  assert.equal(ram.interval, 2000)
})

test("decimals cascade to all variants when not overridden", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["ram"], center: { start: [], end: [] }, end: [] },
    { ram: { kind: "ram", decimals: 2 } },
  )

  const ram = resolved.widgets.ram as ResolvedRamWidgetConfig
  assert.equal(ram.decimals, 2)
  assert.equal(ram.decimalsAlt, 2)
  assert.equal(ram.decimalsVertical, 2)
  assert.equal(ram.decimalsVerticalAlt, 2)
})

test("decimalsVerticalAlt falls back to decimalsVertical, not decimalsAlt", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["ram"], center: { start: [], end: [] }, end: [] },
    { ram: { kind: "ram", decimals: 1, decimalsAlt: 2, decimalsVertical: 0 } },
  )

  const ram = resolved.widgets.ram as ResolvedRamWidgetConfig
  assert.equal(ram.decimals, 1)
  assert.equal(ram.decimalsAlt, 2)
  assert.equal(ram.decimalsVertical, 0)
  assert.equal(ram.decimalsVerticalAlt, 0)
})

test("all decimals variants can be independently overridden", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["ram"], center: { start: [], end: [] }, end: [] },
    {
      ram: {
        kind: "ram",
        decimals: 0,
        decimalsAlt: 1,
        decimalsVertical: 2,
        decimalsVerticalAlt: 3,
      },
    },
  )

  const ram = resolved.widgets.ram as ResolvedRamWidgetConfig
  assert.equal(ram.decimals, 0)
  assert.equal(ram.decimalsAlt, 1)
  assert.equal(ram.decimalsVertical, 2)
  assert.equal(ram.decimalsVerticalAlt, 3)
})

test("rejects a negative decimals value", () => {
  assert.throws(
    () =>
      resolveBarConfiguration(
        { edge: "top", start: ["ram"], center: { start: [], end: [] }, end: [] },
        { ram: { kind: "ram", decimals: -1 } },
      ),
    { name: "BarConfigError" },
  )
})

test("rejects a non-positive interval", () => {
  assert.throws(
    () =>
      resolveBarConfiguration(
        { edge: "top", start: ["ram"], center: { start: [], end: [] }, end: [] },
        { ram: { kind: "ram", interval: 0 } },
      ),
    { name: "BarConfigError" },
  )
})
