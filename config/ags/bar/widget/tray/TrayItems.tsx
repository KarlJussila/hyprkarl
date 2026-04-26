import { For, type Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import AstalTray from "gi://AstalTray"
import TrayItem from "./TrayItem"

type Props = {
  direction: "start" | "end"
  items: Accessor<Array<AstalTray.TrayItem>>
  open: Accessor<boolean>
}

export default function TrayItems({ direction, items, open }: Props) {
  const panelClass = open((isOpen) =>
    isOpen
      ? "tray-panel segmented-group-item open"
      : "tray-panel segmented-group-item",
  )
  const transitionType = direction === "start"
    ? Gtk.RevealerTransitionType.SLIDE_RIGHT
    : Gtk.RevealerTransitionType.SLIDE_LEFT

  return (
    <box class={panelClass}>
      <revealer
        class={`tray-revealer tray-${direction}`}
        transitionType={transitionType}
        transitionDuration={220}
        revealChild={open}
      >
        <box class="tray-item-list segmented-group" spacing={0} overflow={Gtk.Overflow.HIDDEN}>
          <For each={items}>
            {(item) => <TrayItem item={item} />}
          </For>
        </box>
      </revealer>
    </box>
  )
}
