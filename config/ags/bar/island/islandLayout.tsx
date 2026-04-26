import { Gtk } from "ags/gtk4"
import CornerCurve from "../style/CornerCurve"

type IslandEdge =
  | "edge-rounded-start"
  | "edge-rounded-end"
  | "edge-screen-start"
  | "edge-screen-end"

type IslandSide = "start" | "end"

export function normalizeChildren(children?: JSX.Element | Array<JSX.Element>) {
  return children === undefined ? [] : Array.isArray(children) ? children : [children]
}

export function keepNaturalWidth(widget: JSX.Element) {
  if (widget instanceof Gtk.Widget) {
    widget.hexpand = false
  }
}

export function wrapIslandEntry(widget: JSX.Element, className = "island-item") {
  keepNaturalWidth(widget)

  return (
    <box class={className} hexpand={false}>
      {widget}
    </box>
  ) as Gtk.Box
}

export function wrapIslandEntries(
  widgets: Array<JSX.Element>,
  className = "island-item",
) {
  return widgets.map((widget) => wrapIslandEntry(widget, className))
}

function addClasses(widget: JSX.Element | undefined, classes: Array<IslandEdge>) {
  if (!(widget instanceof Gtk.Widget)) return
  classes.forEach((className) => widget.add_css_class(className))
}

export function markOuterIslandEdges(widgets: Array<JSX.Element>, side: IslandSide) {
  const first = widgets[0]
  const last = widgets[widgets.length - 1]

  if (side === "start") {
    addClasses(first, ["edge-screen-start"])
    addClasses(last, ["edge-rounded-end"])
    return
  }

  addClasses(first, ["edge-rounded-start"])
  addClasses(last, ["edge-screen-end"])
}

export function markCenteredIslandEdges(
  startWidgets: Array<JSX.Element>,
  anchor: JSX.Element,
  endWidgets: Array<JSX.Element>,
) {
  const first = startWidgets[0] ?? anchor
  const last = endWidgets[endWidgets.length - 1] ?? anchor

  addClasses(first, ["edge-rounded-start"])
  addClasses(last, ["edge-rounded-end"])
}

export function createOuterCornerCurve(side: IslandSide) {
  return side === "start"
    ? <CornerCurve position="top-left" size={12} radius={4} class="island-curve" />
    : <CornerCurve position="top-right" size={12} radius={4} class="island-curve" />
}

export function createCenterStartCornerCurve() {
  return <CornerCurve position="top-right" size={12} radius={4} class="island-curve" />
}

export function createCenterEndCornerCurve() {
  return <CornerCurve position="top-left" size={12} radius={4} class="island-curve" />
}
