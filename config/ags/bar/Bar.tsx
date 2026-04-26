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

  /* START SIDE WIDGETS */
  const startWidgets: Array<JSX.Element> =
  [
    <Battery monitor={gdkmonitor} />,
    <HyprkarlMenu />,
    <Workspaces />,
    <Tray direction="end" />,
    <Battery monitor={gdkmonitor} />,
  ]

  /* CENTER WIDGETS */
  // Centermost widget (anchored to the center)
  const centerAnchor = <Clock monitor={gdkmonitor} />

  // Start side of center island
  const centerStartWidgets: Array<JSX.Element> =
  [
  ]

  // End side of center island
  const centerEndWidgets =
  [
    <CaffeineToggle />,
  ]

  /* END SIDE WIDGETS */
  const endWidgets: Array<JSX.Element> = [
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
          side="start"
          halign={Gtk.Align.START}
          hexpand={false}
        >
          {startWidgets}
        </Island>

        <Island
          $type="center"
          class="top-center"
          cssName="box"
          halign={Gtk.Align.CENTER}
          hexpand={false}
          start={centerStartWidgets}
          anchor={centerAnchor}
          end={centerEndWidgets}
        />

        <Island
          $type="end"
          class="top-right"
          side="end"
          halign={Gtk.Align.END}
          hexpand={false}
        >
          {endWidgets}
        </Island>
      </centerbox>
    </window>
  )
}
