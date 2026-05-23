import { Gtk } from "ags/gtk4"
import AstalTray from "gi://AstalTray"

export function connectTrayMenuButton(button: Gtk.MenuButton, item: AstalTray.TrayItem) {
  button.menuModel = item.menuModel
  button.insert_action_group("dbusmenu", item.actionGroup)
  item.connect("notify::action-group", () => {
    button.insert_action_group("dbusmenu", item.actionGroup)
  })
}

