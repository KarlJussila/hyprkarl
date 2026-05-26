import assert from "node:assert/strict"
import test from "node:test"
import type { ResolvedBarWidgetDefinition } from "../../widgets/catalog.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedRamWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "ram" }>

test("normalizes ram widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["ram"], center: { start: [], center: [], end: [] }, end: [] },
    { ram: { kind: "ram" } },
  )

  const ram = resolved.widgets.ram as ResolvedRamWidgetConfig
  assert.equal(ram.decimals.primary, 0)
  assert.equal(ram.decimals.alt, 0)
  assert.equal(ram.decimals.vertical, 0)
  assert.equal(ram.decimals.verticalAlt, 0)
  assert.equal(ram.reveal.durationMs, 200)
  assert.equal(ram.interval, 5000)
})

test("decimals cascade to all variants when not overridden", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["ram"], center: { start: [], center: [], end: [] }, end: [] },
    { ram: { kind: "ram", decimals: { primary: 2 } } },
  )

  const ram = resolved.widgets.ram as ResolvedRamWidgetConfig
  assert.equal(ram.decimals.primary, 2)
  assert.equal(ram.decimals.alt, 2)
  assert.equal(ram.decimals.vertical, 2)
  assert.equal(ram.decimals.verticalAlt, 2)
})

test("decimals.verticalAlt falls back to decimals.vertical, not decimals.alt", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["ram"], center: { start: [], center: [], end: [] }, end: [] },
    { ram: { kind: "ram", decimals: { primary: 1, alt: 2, vertical: 0 } } },
  )

  const ram = resolved.widgets.ram as ResolvedRamWidgetConfig
  assert.equal(ram.decimals.primary, 1)
  assert.equal(ram.decimals.alt, 2)
  assert.equal(ram.decimals.vertical, 0)
  assert.equal(ram.decimals.verticalAlt, 0)
})

test("all decimals variants can be independently overridden", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["ram"], center: { start: [], center: [], end: [] }, end: [] },
    {
      ram: {
        kind: "ram",
        decimals: { primary: 0, alt: 1, vertical: 2, verticalAlt: 3 },
      },
    },
  )

  const ram = resolved.widgets.ram as ResolvedRamWidgetConfig
  assert.equal(ram.decimals.primary, 0)
  assert.equal(ram.decimals.alt, 1)
  assert.equal(ram.decimals.vertical, 2)
  assert.equal(ram.decimals.verticalAlt, 3)
})

test("rejects a negative decimals value", () => {
  assert.throws(
    () =>
      resolveBarConfiguration(
        { edge: "top", start: ["ram"], center: { start: [], center: [], end: [] }, end: [] },
        { ram: { kind: "ram", decimals: { primary: -1 } } },
      ),
    { name: "BarConfigError" },
  )
})

test("rejects a non-positive interval", () => {
  assert.throws(
    () =>
      resolveBarConfiguration(
        { edge: "top", start: ["ram"], center: { start: [], center: [], end: [] }, end: [] },
        { ram: { kind: "ram", interval: 0 } },
      ),
    { name: "BarConfigError" },
  )
})
