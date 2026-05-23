import assert from "node:assert/strict"
import test from "node:test"
import type { ResolvedBarWidgetDefinition } from "../../widgets/catalog.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedBluetoothWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "bluetooth" }>

test("normalizes bluetooth widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["bluetooth"], center: { start: [], end: [] }, end: [] },
    { bluetooth: { kind: "bluetooth" } },
  )

  const bluetooth = resolved.widgets.bluetooth as ResolvedBluetoothWidgetConfig
  assert.equal(bluetooth.command, "hk-launch-bluetooth")
  assert.equal(bluetooth.icons.enabled, "")
  assert.equal(bluetooth.icons.disabled, "󰂲")
  assert.equal(bluetooth.tooltip.off, "Bluetooth off")
  assert.equal(bluetooth.tooltip.on, "Bluetooth on")
})

test("allows bluetooth widgets to override their launch command", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["bluetooth"], center: { start: [], end: [] }, end: [] },
    { bluetooth: { kind: "bluetooth", command: "custom-bluetooth-command" } },
  )

  const bluetooth = resolved.widgets.bluetooth as ResolvedBluetoothWidgetConfig
  assert.equal(bluetooth.command, "custom-bluetooth-command")
})

test("allows bluetooth widgets to override icons", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["bluetooth"], center: { start: [], end: [] }, end: [] },
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
    { edge: "top", start: ["bluetooth"], center: { start: [], end: [] }, end: [] },
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
