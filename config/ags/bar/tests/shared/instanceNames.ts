import assert from "node:assert/strict"
import test from "node:test"
import { createWidgetDropdownName } from "../../widgets/shared/instanceNames.ts"

test("uses widget IDs to make same-kind dropdown window names unique", () => {
  assert.equal(
    createWidgetDropdownName("calendar-menu", "clockCompact", "eDP-1"),
    "calendar-menu-clockCompact-eDP-1",
  )
  assert.equal(
    createWidgetDropdownName("battery-menu", "batterySecondary"),
    "battery-menu-batterySecondary-monitor",
  )
})
