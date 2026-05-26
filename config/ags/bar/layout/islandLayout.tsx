import { Gtk } from "ags/gtk4"
import { type BarPlacement, placementClasses } from "./placement"
import CornerCurve from "../styles/CornerCurve"

type IslandEdge =
  | "segment-edge-rounded-start"
  | "segment-edge-rounded-end"
  | "segment-edge-screen-start"
  | "segment-edge-screen-end"

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

// --- Collapsible segment support ---
//
// When a widget sets visible=false on itself, its bar-segment wrapper automatically
// hides and transfers edge-rounding classes to the adjacent segment so the
// neighbor renders correctly. Works for any widget in any island position.

const EDGE_CLASSES: IslandEdge[] = [
  "segment-edge-rounded-start",
  "segment-edge-rounded-end",
  "segment-edge-screen-start",
  "segment-edge-screen-end",
]

function segmentInSlot(slot: Gtk.Widget | null, direction: "first" | "last"): Gtk.Widget | undefined {
  if (!(slot instanceof Gtk.Widget)) return undefined
  let child = slot.get_first_child()
  while (child) {
    if (child instanceof Gtk.Widget && child.has_css_class("bar-island-balance-content")) {
      let seg = direction === "first" ? child.get_first_child() : child.get_last_child()
      while (seg) {
        if (seg instanceof Gtk.Widget && seg.has_css_class("bar-segment")) return seg
        seg = direction === "first" ? seg.get_next_sibling() : seg.get_prev_sibling()
      }
    }
    child = child.get_next_sibling()
  }
  return undefined
}

// For the center start/end and outer island cases: find the nearest bar-segment
// sibling at the segment level (outer island) or at the balance-slot level (center
// island), skipping non-segment siblings like corner curves.
function findSideNeighbor(segment: Gtk.Widget): Gtk.Widget | undefined {
  const next = segment.get_next_sibling()
  if (next instanceof Gtk.Widget && next.has_css_class("bar-segment")) return next

  const prev = segment.get_prev_sibling()
  if (prev instanceof Gtk.Widget && prev.has_css_class("bar-segment")) return prev

  // Center island: segment is inside bar-island-balance-content > bar-island-balance-slot.
  // The adjacent segment is a sibling of the balance-slot in bar-island-center.
  const balanceSlot = segment.get_parent()?.get_parent()
  if (!(balanceSlot instanceof Gtk.Widget)) return undefined

  const slotNext = balanceSlot.get_next_sibling()
  if (slotNext instanceof Gtk.Widget && slotNext.has_css_class("bar-segment")) return slotNext

  const slotPrev = balanceSlot.get_prev_sibling()
  if (slotPrev instanceof Gtk.Widget && slotPrev.has_css_class("bar-segment")) return slotPrev

  return undefined
}

function transferEdgeClasses(from: Gtk.Widget, to: Gtk.Widget, log: IslandEdge[]) {
  for (const cls of EDGE_CLASSES) {
    if (from.has_css_class(cls)) {
      from.remove_css_class(cls)
      to.add_css_class(cls)
      log.push(cls)
    }
  }
}

function reclaimEdgeClasses(from: Gtk.Widget, to: Gtk.Widget, log: IslandEdge[]) {
  for (const cls of log) {
    from.remove_css_class(cls)
    to.add_css_class(cls)
  }
  log.length = 0
}

function setupSegmentCollapse(segment: Gtk.Box, child: Gtk.Widget) {
  segment.connect("realize", () => {
    const segmentParent = segment.get_parent()
    if (!(segmentParent instanceof Gtk.Widget)) return

    let hide: () => void
    let show: () => void

    if (segmentParent.has_css_class("bar-island-center")) {
      // The widget is the center island anchor. Its siblings are balance-slots,
      // not bar-segments — look inside them for the actual neighbor segments.
      const startNeighbor = segmentInSlot(segment.get_prev_sibling(), "last")
      const endNeighbor = segmentInSlot(segment.get_next_sibling(), "first")

      if (!startNeighbor && !endNeighbor) {
        // Solo anchor: hide the whole island so corner curves don't render alone.
        hide = () => { segmentParent.visible = false }
        show = () => { segmentParent.visible = true }
      } else {
        const startBorrowed: IslandEdge[] = []
        const endBorrowed: IslandEdge[] = []
        hide = () => {
          if (startNeighbor) transferEdgeClasses(segment, startNeighbor, startBorrowed)
          if (endNeighbor) transferEdgeClasses(segment, endNeighbor, endBorrowed)
          segment.visible = false
        }
        show = () => {
          if (startNeighbor) reclaimEdgeClasses(startNeighbor, segment, startBorrowed)
          if (endNeighbor) reclaimEdgeClasses(endNeighbor, segment, endBorrowed)
          segment.visible = true
        }
      }
    } else {
      // Widget is in center start/end or an outer island. Find the nearest
      // bar-segment sibling (walking up to balance-slot level for center islands).
      const neighbor = findSideNeighbor(segment)
      const borrowed: IslandEdge[] = []
      hide = () => {
        if (neighbor) transferEdgeClasses(segment, neighbor, borrowed)
        segment.visible = false
      }
      show = () => {
        if (neighbor) reclaimEdgeClasses(neighbor, segment, borrowed)
        segment.visible = true
      }
    }

    if (!child.visible) hide()

    child.connect("notify::visible", () => {
      if (child.visible) show()
      else hide()
    })
  })
}

// --- Island layout helpers ---

export function wrapIslandEntry(
  widget: JSX.Element,
  placement: BarPlacement,
  className = "bar-segment",
) {
  if (placement.isVertical) {
    allowVerticalFill(widget)
  } else {
    keepNaturalWidth(widget)
  }

  const segment = (
    <box class={className} hexpand={placement.isVertical}>
      {widget}
    </box>
  ) as Gtk.Box

  if (widget instanceof Gtk.Widget) {
    setupSegmentCollapse(segment, widget)
  }

  return segment
}

export function wrapIslandEntries(
  widgets: Array<JSX.Element>,
  placement: BarPlacement,
  className = "bar-segment",
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
    addClasses(first, ["segment-edge-screen-start"])
    addClasses(last, ["segment-edge-rounded-end"])
    return
  }

  addClasses(first, ["segment-edge-rounded-start"])
  addClasses(last, ["segment-edge-screen-end"])
}

export function markCenteredIslandEdges(
  startWidgets: Array<JSX.Element>,
  anchor: JSX.Element,
  endWidgets: Array<JSX.Element>,
) {
  const first = startWidgets[0] ?? anchor
  const last = endWidgets[endWidgets.length - 1] ?? anchor

  addClasses(first, ["segment-edge-rounded-start"])
  addClasses(last, ["segment-edge-rounded-end"])
}

export function markCenteredGroupEdges(widgets: Array<JSX.Element>) {
  const first = widgets[0]
  const last = widgets[widgets.length - 1]

  addClasses(first, ["segment-edge-rounded-start"])
  addClasses(last, ["segment-edge-rounded-end"])
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
      class="bar-island-curve"
    />
  )
}

export function createCenterStartCornerCurve(placement: BarPlacement) {
  return <CornerCurve position={centerStartCornerPosition(placement)} size={12} radius={4} class="bar-island-curve" />
}

export function createCenterEndCornerCurve(placement: BarPlacement) {
  return <CornerCurve position={centerEndCornerPosition(placement)} size={12} radius={4} class="bar-island-curve" />
}
