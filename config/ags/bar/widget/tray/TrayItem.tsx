import { createBinding } from "ags"
import { Gtk } from "ags/gtk4"
import AstalTray from "gi://AstalTray"
import { connectTrayMenuButton } from "./connectTrayMenuButton"

type Props = {
  item: AstalTray.TrayItem
}

export default function TrayItem({ item }: Props) {
  return (
    <menubutton
      class="tray-item segmented-inline-item"
      tooltipMarkup={createBinding(item, "tooltipMarkup")}
      $={(self) => connectTrayMenuButton(self, item)}
    >
      <image gicon={createBinding(item, "gicon")} pixelSize={14} />
    </menubutton>
  ) as Gtk.MenuButton
}
