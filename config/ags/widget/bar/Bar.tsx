import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import HyprkarlMenu from "./element/HyprkarlMenu"
import Clock from "./element/Clock"
import CornerCurve from "./element/CornerCurve"
import CaffeineToggle from "./element/CaffeineToggle"
import AnchoredCenterBox from "./element/AnchoredCenterBox"

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  /*********************/
  /* WIDGET PLACEMENTS */
  /*********************/
  
  /* LEFT SIDE WIDGETS */
  const leftWidgets: Array<JSX.Element> =
  [
    <HyprkarlMenu />,
  ]

  /* CENTER WIDGETS */
  // Centermost widget (anchored to the center)
  const centerAnchor = <Clock />

  // Left side of center island
  const centerStartWidgets: Array<JSX.Element> =
  [
  
  ]

  // Right side of center island
  const centerEndWidgets =
  [
    <CaffeineToggle />,
  ]

  /* RIGHT SIDE WIDGETS */
  const rightWidgets: Array<JSX.Element> = [
    <Clock />
  ]

  /* Overall Bar Layout */
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
          {leftWidgets}
          <CornerCurve position="top-left" size={12} radius={4} class="border-curve" />
        </box>

        <AnchoredCenterBox
          $type="center"
          class="top-center"
          cssName="box"
          halign={Gtk.Align.CENTER}
          hexpand={false}
          start={centerStartWidgets}
          anchor={centerAnchor}
          end={centerEndWidgets}
        />

        <box
          $type="end"
          class="top-right"
          halign={Gtk.Align.END}
          hexpand={false}
        >
          <CornerCurve position="top-right" size={12} radius={4} class="border-curve" />
          {rightWidgets}
        </box>
      </centerbox>
    </window>
  )
}
