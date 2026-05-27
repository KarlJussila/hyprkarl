import assert from "node:assert/strict"
import test from "node:test"
import {
  composeObject,
  normalizeBoolean,
  normalizeStringValue,
  widgetContext,
} from "../../widgets/shared/normalize.ts"
import { BarConfigError } from "../../configError.ts"

const tooltipNormalizer = composeObject({
  enabled: normalizeBoolean,
  text: normalizeStringValue,
})

const defaults = { enabled: true, text: "hello" }

test("composeObject returns defaults when given undefined", () => {
  const resolved = tooltipNormalizer(widgetContext("w"), undefined, defaults)
  assert.deepEqual(resolved, { enabled: true, text: "hello" })
})

test("composeObject merges per-field overrides with defaults", () => {
  const resolved = tooltipNormalizer(widgetContext("w"), { text: "world" }, defaults)
  assert.deepEqual(resolved, { enabled: true, text: "world" })
})

test("composeObject reports field-level errors with child context", () => {
  let caught: BarConfigError | null = null
  try {
    tooltipNormalizer(widgetContext("w"), { enabled: "yes" as unknown as boolean }, defaults)
  } catch (err) {
    caught = err as BarConfigError
  }
  assert.ok(caught instanceof BarConfigError)
  assert.equal(caught.path, "w.enabled")
  assert.equal(caught.message, "must be true or false")
})

test("composeObject rejects non-object values", () => {
  assert.throws(
    () => tooltipNormalizer(widgetContext("w"), "nope" as unknown as { text?: string }, defaults),
    BarConfigError,
  )
})

test("composeObject nests via outer composeObject", () => {
  const outer = composeObject({
    tooltip: tooltipNormalizer,
    label: normalizeStringValue,
  })
  const outerDefaults = { tooltip: defaults, label: "default" }
  const resolved = outer(widgetContext("w"), { tooltip: { text: "inner" } }, outerDefaults)
  assert.deepEqual(resolved, { tooltip: { enabled: true, text: "inner" }, label: "default" })
})
