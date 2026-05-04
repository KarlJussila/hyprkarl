import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { type BarOrientation } from "../barPlacement"
import Button from "../button/Button"

type Props = {
  orientation: BarOrientation
}

export default function HyprkarlMenu({ orientation }: Props) {
  const isVertical = orientation === "vertical"

  return (
    <Button
      class="menu-button"
      hexpand={isVertical}
      halign={isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      execPrimary={() => execAsync("hyprkarl-menu").catch(() => {})}
    >
      <box hexpand={isVertical} halign={Gtk.Align.CENTER}>
        <label xalign={0.5} label="" />
      </box>
    </Button>
  )
}
