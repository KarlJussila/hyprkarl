import { For, type Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import AstalTray from "gi://AstalTray"
import TrayItem from "./TrayItem"

type Props = {
  direction: "left" | "right"
  items: Accessor<Array<AstalTray.TrayItem>>
  open: Accessor<boolean>
}

export default function TrayItems({ direction, items, open }: Props) {
  const panelClass = open((isOpen) =>
    isOpen
      ? "tray-panel segmented-inline-item open"
      : "tray-panel segmented-inline-item",
  )
  const transitionType = direction === "left"
    ? Gtk.RevealerTransitionType.SLIDE_RIGHT
    : Gtk.RevealerTransitionType.SLIDE_LEFT

  return (
    <box class={panelClass}>
      <revealer
        class={`tray-revealer tray-revealer-${direction}`}
        transitionType={transitionType}
        transitionDuration={220}
        revealChild={open}
      >
        <box class="tray-items segmented-inline" spacing={0} overflow={Gtk.Overflow.HIDDEN}>
          <For each={items}>
            {(item) => <TrayItem item={item} />}
          </For>
        </box>
      </revealer>
    </box>
  )
}
