import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import HyprkarlMenu from "./element/HyprkarlMenu"
import Clock from "./element/Clock"
import CornerCurve from "./element/CornerCurve"

/* Main Bar */
export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible
      name="bar"
      class="Bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox cssName="centerbox">
        <box
          $type="start"
          class="top-left"
          halign={Gtk.Align.START}
          hexpand={false}
        >
          <HyprkarlMenu />
          <CornerCurve position="top-left" size={12} radius={4} class="border-curve" />
        </box>

        <box
          $type="center"
          class="top-center"
          cssName="box"
          halign={Gtk.Align.CENTER}
          hexpand={false}
        >
          <CornerCurve position="top-right" size={12} radius={4} class="border-curve" />
          <Clock />
          <CornerCurve position="top-left" size={12} radius={4} class="border-curve" />
        </box>
      </centerbox>
    </window>
  )
}
