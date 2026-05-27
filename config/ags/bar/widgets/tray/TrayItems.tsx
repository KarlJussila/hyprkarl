import { Accessor, For, createComputed } from "ags"
import { Gtk } from "ags/gtk4"
import AstalTray from "gi://AstalTray"
import { type TrayPlacement } from "../../layout/placement"
import TrayItem from "./TrayItem"
import type { TrayDirection } from "./spec.tsx"

type Props = {
  placement: TrayPlacement
  direction: TrayDirection
  items: Accessor<Array<AstalTray.TrayItem>>
  open: Accessor<boolean>
  revealDurationMs: number
}

export default function TrayItems({ placement, direction, items, open, revealDurationMs }: Props) {
  const panelClass = open((isOpen) =>
    `widget-tray-panel widget-group-item${isOpen ? " is-open" : ""}`,
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
      transitionDuration={revealDurationMs}
      revealChild={open}
    >
      <box
        class={`widget-tray-item-list widget-group is-${placement.orientation}`}
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
