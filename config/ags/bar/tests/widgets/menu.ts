import assert from "node:assert/strict"
import test from "node:test"
import type { NormalizedMenuWidgetConfig } from "../../configuration.ts"
import { resolveBarConfiguration } from "../support/index.ts"

test("normalizes menu widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["menu"],
      center: {
        start: [],
        end: [],
      },
      end: [],
    },
    {
      menu: { kind: "menu" },
    },
  )

  const menu = resolved.widgets.menu as NormalizedMenuWidgetConfig
  assert.equal(menu.icon, "")
  assert.equal(menu.commands.primary, "hk-menu")
  assert.equal(menu.commands.secondary, undefined)
})
