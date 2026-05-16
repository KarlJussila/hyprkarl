import assert from "node:assert/strict"
import test from "node:test"
import type { ResolvedBarWidgetDefinition } from "../../widgets/widgetTypes.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedTrayWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "tray" }>

test("normalizes tray widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["tray"],
      center: {
        start: [],
        end: [],
      },
      end: [],
    },
    {
      tray: { kind: "tray" },
    },
  )

  const tray = resolved.widgets.tray as ResolvedTrayWidgetConfig
  assert.equal(tray.direction, "start")
  assert.equal(tray.mirrorTrigger, false)
  assert.equal(tray.reveal.durationMs, 220)
})
