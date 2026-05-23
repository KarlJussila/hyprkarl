import { createBinding } from "ags"
import { Gtk } from "ags/gtk4"
import AstalTray from "gi://AstalTray"
import { connectTrayMenuButton } from "./connectTrayMenuButton"

type Props = {
  fill?: boolean
  item: AstalTray.TrayItem
}

export default function TrayItem({ fill = false, item }: Props) {
  return (
    <menubutton
      class="widget-tray-item widget-group-item"
      hexpand={fill}
      halign={fill ? Gtk.Align.FILL : Gtk.Align.CENTER}
      tooltipMarkup={createBinding(item, "tooltipMarkup")}
      $={(self) => connectTrayMenuButton(self, item)}
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
