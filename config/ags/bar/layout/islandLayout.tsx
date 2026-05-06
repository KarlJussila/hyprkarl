import { Gtk } from "ags/gtk4"
import { type BarPlacement } from "./placement"
import CornerCurve from "../styles/CornerCurve"

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
    widget.vexpand = false
  }
}

function allowVerticalFill(widget: JSX.Element) {
  if (widget instanceof Gtk.Widget) {
    widget.vexpand = false
  }
}

export function wrapIslandEntry(
  widget: JSX.Element,
  placement: BarPlacement,
  className = "island-item",
) {
  if (placement.isVertical) {
    allowVerticalFill(widget)
  } else {
    keepNaturalWidth(widget)
  }

  return (
    <box class={className} hexpand={placement.isVertical}>
      {widget}
    </box>
  ) as Gtk.Box
}

export function wrapIslandEntries(
  widgets: Array<JSX.Element>,
  placement: BarPlacement,
  className = "island-item",
) {
  return widgets.map((widget) => wrapIslandEntry(widget, placement, className))
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

function outerCornerPosition(placement: BarPlacement, side: IslandSide) {
  switch (placement.edge) {
    case "bottom":
      return side === "start" ? "bottom-left" : "bottom-right"

    case "left":
      return side === "start" ? "top-left" : "bottom-left"

    case "right":
      return side === "start" ? "top-right" : "bottom-right"

    case "top":
    default:
      return side === "start" ? "top-left" : "top-right"
  }
}

function centerStartCornerPosition(placement: BarPlacement) {
  switch (placement.edge) {
    case "bottom":
      return "bottom-right"

    case "left":
      return "bottom-left"

    case "right":
      return "bottom-right"

    case "top":
    default:
      return "top-right"
  }
}

function centerEndCornerPosition(placement: BarPlacement) {
  switch (placement.edge) {
    case "bottom":
      return "bottom-left"

    case "left":
      return "top-left"

    case "right":
      return "top-right"

    case "top":
    default:
      return "top-left"
  }
}

export function createOuterCornerCurve(placement: BarPlacement, side: IslandSide) {
  return (
    <CornerCurve
      position={outerCornerPosition(placement, side)}
      size={12}
      radius={4}
      class="island-curve"
    />
  )
}

export function createCenterStartCornerCurve(placement: BarPlacement) {
  return <CornerCurve position={centerStartCornerPosition(placement)} size={12} radius={4} class="island-curve" />
}

export function createCenterEndCornerCurve(placement: BarPlacement) {
  return <CornerCurve position={centerEndCornerPosition(placement)} size={12} radius={4} class="island-curve" />
}

