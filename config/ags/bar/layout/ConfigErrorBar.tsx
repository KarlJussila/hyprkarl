import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import { type BarConfigError } from "../configError"
import { type BarEdge } from "../types"
import { createBarPlacement, placementClasses } from "./placement"

type Props = {
  edge: BarEdge
  error: BarConfigError
  monitor: Gdk.Monitor
}

function errorLocationLabel(error: BarConfigError) {
  if (error.path) {
    return `${error.sourceFile}: ${error.path}`
  }

  return error.sourceFile
}

export default function ConfigErrorBar({ edge, error, monitor }: Props) {
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
      tooltipText={error.message}
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
          <label class="bar-config-error-path" xalign={0.5} label={errorLocationLabel(error)} />
        </box>
      </box>
    </window>
  )
}
