import { createBinding } from "ags"
import { Gtk } from "ags/gtk4"
import AstalTray from "gi://AstalTray"

type Props = {
  fill?: boolean
  item: AstalTray.TrayItem
}

function connectMenuButton(button: Gtk.MenuButton, item: AstalTray.TrayItem) {
  button.menuModel = item.menuModel
  button.insert_action_group("dbusmenu", item.actionGroup)
  item.connect("notify::action-group", () => {
    button.insert_action_group("dbusmenu", item.actionGroup)
  })
}

export default function TrayItem({ fill = false, item }: Props) {
  return (
    <menubutton
      class="widget-tray-item widget-group-item"
      hexpand={fill}
      halign={fill ? Gtk.Align.FILL : Gtk.Align.CENTER}
      tooltipMarkup={createBinding(item, "tooltipMarkup")}
      $={(self) => connectMenuButton(self, item)}
    >
      <image
        gicon={createBinding(item, "gicon")}
        pixelSize={14}
        halign={Gtk.Align.CENTER}
        hexpand={fill}
      />
    </menubutton>
  ) as Gtk.MenuButton
}
