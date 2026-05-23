import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import { createEffect, onCleanup } from "ags"
import type { BarEdge } from "../configuration"
import type { BarVisibilityController } from "./barVisibilityController"

const HOTZONE_THICKNESS = 1

const hotzoneAnchor: Record<BarEdge, number> = {
  top:    Astal.WindowAnchor.TOP | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT,
  bottom: Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT,
  left:   Astal.WindowAnchor.LEFT | Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM,
  right:  Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM,
}

export function createHotzoneWindow({
  edge,
  gdkmonitor,
  controller,
}: {
  edge: BarEdge
  gdkmonitor: Gdk.Monitor
  controller: BarVisibilityController
}) {
  const isVertical = edge === "left" || edge === "right"
  const { width: monitorWidth, height: monitorHeight } = gdkmonitor.get_geometry()

  const win = new Astal.Window({
    name: "bar-hotzone",
    gdkmonitor,
    application: app,
    anchor: hotzoneAnchor[edge],
    exclusivity: Astal.Exclusivity.NORMAL,
    layer: Astal.Layer.TOP,
    visible: false,
  })
  win.add_css_class("bar-hotzone-window")

  const box = new Gtk.Box({
    canTarget: true,
    widthRequest: isVertical ? HOTZONE_THICKNESS : monitorWidth,
    heightRequest: isVertical ? monitorHeight : HOTZONE_THICKNESS,
  })

  // Evil pixel hack (need to render something to register mouse events)
  const probe = new Gtk.Box({
    halign: Gtk.Align.START,
    valign: Gtk.Align.START,
    widthRequest: 1,
    heightRequest: 1,
  })
  probe.add_css_class("bar-hotzone-probe")
  box.append(probe)
  win.set_child(box)

  const motion = new Gtk.EventControllerMotion()
  motion.connect("motion", () => controller.onPointerEnter())
  box.add_controller(motion)

  createEffect(() => {
    win.visible = !controller.windowVisible()
  })

  onCleanup(() => win.destroy())
}
