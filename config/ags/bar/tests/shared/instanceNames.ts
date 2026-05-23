import assert from "node:assert/strict"
import test from "node:test"
import { createWidgetFlyoutName } from "../../widgets/shared/instanceNames.ts"

test("uses widget IDs to make same-kind flyout window names unique", () => {
  assert.equal(
    createWidgetFlyoutName("calendar-menu", "clockCompact", "eDP-1"),
    "calendar-menu-clockCompact-eDP-1",
  )
  assert.equal(
    createWidgetFlyoutName("battery-menu", "batterySecondary"),
    "battery-menu-batterySecondary-monitor",
  )
})
