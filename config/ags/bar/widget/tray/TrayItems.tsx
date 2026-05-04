import { For, createComputed, type Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import AstalTray from "gi://AstalTray"
import { type TrayPlacement } from "../../barPlacement"
import TrayItem from "./TrayItem"

type Props = {
  placement: TrayPlacement
  direction: "start" | "end"
  items: Accessor<Array<AstalTray.TrayItem>>
  open: Accessor<boolean>
}

export default function TrayItems({ placement, direction, items, open }: Props) {
  const panelClass = open((isOpen) =>
    isOpen
      ? "tray-panel segmented-group-item open"
      : "tray-panel segmented-group-item",
  )
  const transitionType = placement.tray.revealTransition[direction]
  const revealerClass = createComputed(() =>
    `${panelClass()} tray-revealer tray-${direction} edge-${placement.edge}`,
  )

  return (
    <revealer
      class={revealerClass}
      hexpand={placement.isVertical}
      halign={Gtk.Align.FILL}
      transitionType={transitionType}
      transitionDuration={220}
      revealChild={open}
    >
      <box
        class={`tray-item-list segmented-group orientation-${placement.orientation}`}
        spacing={0}
        overflow={Gtk.Overflow.HIDDEN}
        orientation={placement.layoutOrientation}
        hexpand={placement.isVertical}
        halign={placement.isVertical ? Gtk.Align.FILL : Gtk.Align.START}
      >
        <For each={items}>
          {(item) => <TrayItem item={item} fill={placement.isVertical} />}
        </For>
      </box>
    </revealer>
  )
}
