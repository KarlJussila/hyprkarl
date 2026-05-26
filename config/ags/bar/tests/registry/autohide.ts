import assert from "node:assert/strict"
import test from "node:test"
import { BAR_LAYOUT_SOURCE_FILE, formatBarConfigError } from "../../configError.ts"
import type { BarLayoutConfig } from "../../configuration.ts"
import { expectBarConfigError, resolveBarConfiguration } from "../support/index.ts"

const minimalWidgets = {
  menu: { kind: "menu" as const },
  clock: { kind: "clock" as const },
}

const minimalLayout: BarLayoutConfig = {
  edge: "top",
  start: ["menu"],
  center: { start: [], center: ["clock"], end: [] },
  end: [],
}

test("autohide defaults to false", () => {
  const resolved = resolveBarConfiguration(minimalLayout, minimalWidgets)
  assert.equal(resolved.autohide, false)
})

test("exclusive defaults to true when autohide is off", () => {
  const resolved = resolveBarConfiguration(minimalLayout, minimalWidgets)
  assert.equal(resolved.exclusive, true)
})

test("exclusive defaults to false when autohide is on", () => {
  const resolved = resolveBarConfiguration(
    { ...minimalLayout, autohide: true },
    minimalWidgets,
  )
  assert.equal(resolved.autohide, true)
  assert.equal(resolved.exclusive, false)
})

test("exclusive can be explicitly true even with autohide on", () => {
  const resolved = resolveBarConfiguration(
    { ...minimalLayout, autohide: true, exclusive: true },
    minimalWidgets,
  )
  assert.equal(resolved.autohide, true)
  assert.equal(resolved.exclusive, true)
})

test("exclusive can be explicitly false even with autohide off", () => {
  const resolved = resolveBarConfiguration(
    { ...minimalLayout, autohide: false, exclusive: false },
    minimalWidgets,
  )
  assert.equal(resolved.autohide, false)
  assert.equal(resolved.exclusive, false)
})

test("rejects non-boolean autohide value", () => {
  const layout = { ...minimalLayout, autohide: "yes" } as unknown as BarLayoutConfig
  const error = expectBarConfigError(() => resolveBarConfiguration(layout, minimalWidgets))
  assert.equal(error.sourceFile, BAR_LAYOUT_SOURCE_FILE)
  assert.equal(error.path, "autohide")
  assert.equal(error.message, "must be true or false")
  assert.equal(
    formatBarConfigError(error),
    "Bar config error in layout.config.ts at autohide: must be true or false",
  )
})

test("rejects non-boolean exclusive value", () => {
  const layout = { ...minimalLayout, exclusive: "yes" } as unknown as BarLayoutConfig
  const error = expectBarConfigError(() => resolveBarConfiguration(layout, minimalWidgets))
  assert.equal(error.sourceFile, BAR_LAYOUT_SOURCE_FILE)
  assert.equal(error.path, "exclusive")
  assert.equal(error.message, "must be true or false")
  assert.equal(
    formatBarConfigError(error),
    "Bar config error in layout.config.ts at exclusive: must be true or false",
  )
})
