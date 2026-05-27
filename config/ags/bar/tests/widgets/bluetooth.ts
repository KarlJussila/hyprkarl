import assert from "node:assert/strict"
import test from "node:test"
import type { ResolvedBarWidgetDefinition } from "../../widgets/catalog.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedBluetoothWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "bluetooth" }>

test("normalizes bluetooth widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["bluetooth"], center: { start: [], center: [], end: [] }, end: [] },
    { bluetooth: { kind: "bluetooth" } },
  )

  const bluetooth = resolved.widgets.bluetooth as ResolvedBluetoothWidgetConfig
  assert.equal(bluetooth.commands.primary, "hk-launch-bluetooth")
  assert.equal(bluetooth.commands.secondary, undefined)
  assert.equal(bluetooth.commands.tertiary, undefined)
  assert.ok(bluetooth.icons.enabled.length >= 0)
  assert.ok(bluetooth.icons.disabled.length > 0)
  assert.equal(bluetooth.tooltip.off, "Bluetooth off")
  assert.equal(bluetooth.tooltip.on, "Bluetooth on")
})

test("allows bluetooth widgets to override their launch command", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["bluetooth"], center: { start: [], center: [], end: [] }, end: [] },
    { bluetooth: { kind: "bluetooth", commands: { primary: "custom-bluetooth-command" } } },
  )

  const bluetooth = resolved.widgets.bluetooth as ResolvedBluetoothWidgetConfig
  assert.equal(bluetooth.commands.primary, "custom-bluetooth-command")
})

test("allows bluetooth widgets to add secondary and tertiary commands", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["bluetooth"], center: { start: [], center: [], end: [] }, end: [] },
    {
      bluetooth: {
        kind: "bluetooth",
        commands: { secondary: "bt-secondary", tertiary: "bt-tertiary" },
      },
    },
  )

  const bluetooth = resolved.widgets.bluetooth as ResolvedBluetoothWidgetConfig
  assert.equal(bluetooth.commands.primary, "hk-launch-bluetooth")
  assert.equal(bluetooth.commands.secondary, "bt-secondary")
  assert.equal(bluetooth.commands.tertiary, "bt-tertiary")
})

test("allows bluetooth widgets to override icons", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["bluetooth"], center: { start: [], center: [], end: [] }, end: [] },
    {
      bluetooth: {
        kind: "bluetooth",
        icons: { enabled: "ON", disabled: "OFF" },
      },
    },
  )

  const bluetooth = resolved.widgets.bluetooth as ResolvedBluetoothWidgetConfig
  assert.equal(bluetooth.icons.enabled, "ON")
  assert.equal(bluetooth.icons.disabled, "OFF")
})

test("allows bluetooth widgets to override tooltip templates", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["bluetooth"], center: { start: [], center: [], end: [] }, end: [] },
    {
      bluetooth: {
        kind: "bluetooth",
        tooltip: { off: "BT off", connected: "{count} paired" },
      },
    },
  )

  const bluetooth = resolved.widgets.bluetooth as ResolvedBluetoothWidgetConfig
  assert.equal(bluetooth.tooltip.off, "BT off")
  assert.equal(bluetooth.tooltip.connected, "{count} paired")
})
