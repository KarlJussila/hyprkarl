import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import HyprkarlMenu from "./widget/HyprkarlMenu"
import Clock from "./widget/time/Clock"
import CaffeineToggle from "./widget/CaffeineToggle"
import Battery from "./widget/battery/Battery"
import Workspaces from "./widget/workspaces/Workspaces"
import Tray from "./widget/tray/Tray"
import Island from "./island/Island"

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  /*********************/
  /* WIDGET PLACEMENTS */
  /*********************/
  
  /* LEFT SIDE WIDGETS */
  const leftWidgets: Array<JSX.Element> =
  [
    <Battery monitor={gdkmonitor} />,
    <HyprkarlMenu />,
    <Workspaces />,
    <Tray direction="right" />,
    <Battery monitor={gdkmonitor} />,
  ]

  /* CENTER WIDGETS */
  // Centermost widget (anchored to the center)
  const centerAnchor = <Clock monitor={gdkmonitor} />

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
    <Battery monitor={gdkmonitor} />,
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
        <Island
          $type="start"
          class="top-left"
          side="left"
          halign={Gtk.Align.START}
          hexpand={false}
        >
          {leftWidgets}
        </Island>

        <Island
          $type="center"
          class="top-center"
          cssName="box"
          halign={Gtk.Align.CENTER}
          hexpand={false}
          left={centerStartWidgets}
          anchor={centerAnchor}
          right={centerEndWidgets}
        />

        <Island
          $type="end"
          class="top-right"
          side="right"
          halign={Gtk.Align.END}
          hexpand={false}
        >
          {rightWidgets}
        </Island>
      </centerbox>
    </window>
  )
}
