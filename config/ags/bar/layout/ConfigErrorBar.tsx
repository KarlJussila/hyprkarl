import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import { type BarEdge } from "../types"
import { createBarPlacement, placementClasses } from "./placement"

type Props = {
  edge: BarEdge
  message: string
  monitor: Gdk.Monitor
}

export default function ConfigErrorBar({ edge, message, monitor }: Props) {
  const placement = createBarPlacement(edge)
  const itemOrientation = placement.isVertical
    ? Gtk.Orientation.VERTICAL
    : Gtk.Orientation.HORIZONTAL

  return (
    <window
      visible
      name="bar"
      class={`Bar bar-shell bar-config-error ${placementClasses(placement)}`}
      gdkmonitor={monitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={placement.window.anchor}
      application={app}
      tooltipText={message}
    >
      <box
        class={`bar-config-error-layout bar-layout-root ${placementClasses(placement)}`}
        orientation={placement.layoutOrientation}
      >
        <box
          class={`bar-config-error-item config-error-surface orientation-${placement.orientation} is-${placement.orientation}`}
          orientation={itemOrientation}
          spacing={placement.isVertical ? 4 : 8}
          hexpand={!placement.isVertical}
          vexpand={placement.isVertical}
          halign={placement.isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
          valign={placement.isVertical ? Gtk.Align.START : Gtk.Align.CENTER}
        >
          <label class="bar-config-error-title" xalign={0.5} label="Bar config error" />
          <label class="bar-config-error-path" xalign={0.5} label={message} />
        </box>
      </box>
    </window>
  )
}
