import assert from "node:assert/strict"
import test from "node:test"
import type { ResolvedBarWidgetDefinition } from "../../widgets/catalog.ts"
import { resolveBarConfiguration } from "../support/index.ts"

type ResolvedMenuWidgetConfig = Extract<ResolvedBarWidgetDefinition, { kind: "menu" }>

test("normalizes menu widget defaults from minimal config", () => {
  const resolved = resolveBarConfiguration(
    {
      edge: "top",
      start: ["menu"],
      center: {
        start: [],
        center: [],
        end: [],
      },
      end: [],
    },
    {
      menu: { kind: "menu" },
    },
  )

  const menu = resolved.widgets.menu as ResolvedMenuWidgetConfig
  assert.ok(menu.icon.length >= 0)
  assert.equal(menu.commands.primary, "hk-menu")
  assert.equal(menu.commands.secondary, undefined)
  assert.equal(menu.commands.tertiary, undefined)
})

test("allows menu tertiary command to be configured", () => {
  const resolved = resolveBarConfiguration(
    { edge: "top", start: ["menu"], center: { start: [], center: [], end: [] }, end: [] },
    {
      menu: {
        kind: "menu",
        commands: { primary: "hk-menu", tertiary: "hk-menu-extra" },
      },
    },
  )

  const menu = resolved.widgets.menu as ResolvedMenuWidgetConfig
  assert.equal(menu.commands.primary, "hk-menu")
  assert.equal(menu.commands.tertiary, "hk-menu-extra")
})
