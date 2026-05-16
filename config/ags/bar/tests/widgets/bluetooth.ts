import assert from "node:assert/strict"
import test from "node:test"
import type { ResolvedBarWidgetDefinition } from "../../widgets/widgetTypes.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedBluetoothWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "bluetooth" }>

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

  const bluetooth = resolved.widgets.bluetooth as ResolvedBluetoothWidgetConfig
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

  const bluetooth = resolved.widgets.bluetooth as ResolvedBluetoothWidgetConfig
  assert.equal(bluetooth.command, "custom-bluetooth-command")
})
