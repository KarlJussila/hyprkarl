import assert from "node:assert/strict"
import test from "node:test"
import type { NormalizedBluetoothWidgetConfig } from "../../configuration.ts"
import { resolveBarConfiguration } from "../support/index.ts"

test("normalizes bluetooth widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["bluetooth"],
      center: {
        start: [],
        end: [],
      },
      end: [],
    },
    {
      bluetooth: { kind: "bluetooth" },
    },
  )

  const bluetooth = resolved.widgets.bluetooth as NormalizedBluetoothWidgetConfig
  assert.equal(bluetooth.command, "hk-launch-bluetooth")
})

test("allows bluetooth widgets to override their launch command", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["bluetooth"],
      center: {
        start: [],
        end: [],
      },
      end: [],
    },
    {
      bluetooth: {
        kind: "bluetooth",
        command: "custom-bluetooth-command",
      },
    },
  )

  const bluetooth = resolved.widgets.bluetooth as NormalizedBluetoothWidgetConfig
  assert.equal(bluetooth.command, "custom-bluetooth-command")
})
