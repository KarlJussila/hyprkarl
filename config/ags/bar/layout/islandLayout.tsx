import { Gtk } from "ags/gtk4"
import { type BarPlacement, placementClasses } from "./placement"
import CornerCurve from "./CornerCurve"

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
//
// Edge classes propagate in a fixed direction: *-start classes move toward the
// next segment (away from the start edge), *-end classes move toward the previous
// segment. When hiding, we walk past already-hidden segments to find the nearest
// visible target. The borrowed log records the actual holder so reclaim always
// finds the right widget, even when multiple collapsible widgets are stacked at
// the same edge.
//
// The center island uses a flat ordered list spanning all three parts
// (start-slot segments → center-group segments → end-slot segments) so propagation
// crosses slot boundaries correctly when adjacent collapsible widgets straddle
// the center-group/slot seam.

const EDGE_CLASSES: IslandEdge[] = [
  "segment-edge-rounded-start",
  "segment-edge-rounded-end",
  "segment-edge-screen-start",
  "segment-edge-screen-end",
]

const EDGE_CLASS_PROPAGATION_DIR: Record<IslandEdge, "next" | "prev"> = {
  "segment-edge-rounded-start": "next",
  "segment-edge-screen-start": "next",
  "segment-edge-rounded-end": "prev",
  "segment-edge-screen-end": "prev",
}

type BorrowedClass = { cls: IslandEdge; holder: Gtk.Widget }

// Walk direct siblings in one direction, skipping non-segment widgets (e.g. corner curves).
function nextSegmentSibling(seg: Gtk.Widget, dir: "next" | "prev"): Gtk.Widget | undefined {
  let sib: Gtk.Widget | null = dir === "next" ? seg.get_next_sibling() : seg.get_prev_sibling()
  while (sib instanceof Gtk.Widget) {
    if (sib.has_css_class("bar-segment")) return sib
    sib = dir === "next" ? sib.get_next_sibling() : sib.get_prev_sibling()
  }
  return undefined
}

// Walk segment siblings in one direction, skipping hidden segments.
function findVisibleSegmentNeighbor(segment: Gtk.Widget, dir: "next" | "prev"): Gtk.Widget | undefined {
  let candidate = nextSegmentSibling(segment, dir)
  while (candidate) {
    if (candidate.visible) return candidate
    candidate = nextSegmentSibling(candidate, dir)
  }
  return undefined
}

// Return the bar-island-center container for any segment inside a center island,
// whether it is a direct child, inside a center group, or inside a balance slot.
function getCenterIsland(segment: Gtk.Widget): Gtk.Widget | undefined {
  const parent = segment.get_parent()
  if (!(parent instanceof Gtk.Widget)) return undefined
  if (parent.has_css_class("bar-island-center")) return parent
  // Center group widget: segment → bar-island-center-group → bar-island-center
  if (parent.has_css_class("bar-island-center-group")) {
    const island = parent.get_parent()
    if (island instanceof Gtk.Widget && island.has_css_class("bar-island-center")) return island
    return undefined
  }
  // Slot widget: segment → balance-content → balance-slot → bar-island-center
  const balanceSlot = parent.get_parent()
  if (!(balanceSlot instanceof Gtk.Widget)) return undefined
  const island = balanceSlot.get_parent()
  if (island instanceof Gtk.Widget && island.has_css_class("bar-island-center")) return island
  return undefined
}

// Collect all bar-segments from inside a balance-slot in DOM order.
function segmentsInBalanceSlot(slot: Gtk.Widget): Gtk.Widget[] {
  const segments: Gtk.Widget[] = []
  let child = slot.get_first_child()
  while (child instanceof Gtk.Widget) {
    if (child.has_css_class("bar-island-balance-content")) {
      let seg = child.get_first_child()
      while (seg instanceof Gtk.Widget) {
        if (seg.has_css_class("bar-segment")) segments.push(seg)
        seg = seg.get_next_sibling()
      }
    }
    child = child.get_next_sibling()
  }
  return segments
}

type CenterIslandLayout = { segments: Gtk.Widget[]; spacers: Gtk.Widget[] }

// Single pass over centerIsland's direct children that collects:
//   segments — flat ordered list [startSlot..., center..., endSlot...]
//   spacers  — hexpand pusher widgets inside each balance slot
// Works for flat (no-pivot), single-pivot, and multi-pivot center island layouts.
function collectCenterIslandLayout(centerIsland: Gtk.Widget): CenterIslandLayout {
  const segments: Gtk.Widget[] = []
  const spacers: Gtk.Widget[] = []
  let child = centerIsland.get_first_child()
  while (child instanceof Gtk.Widget) {
    if (child.has_css_class("bar-segment")) {
      segments.push(child)
    } else if (child.has_css_class("bar-island-center-group")) {
      // Multi-widget center group: collect segments directly inside it
      let seg = child.get_first_child()
      while (seg instanceof Gtk.Widget) {
        if (seg.has_css_class("bar-segment")) segments.push(seg)
        seg = seg.get_next_sibling()
      }
    } else if (child.has_css_class("bar-island-balance-slot")) {
      segments.push(...segmentsInBalanceSlot(child))
      const isStart = child.has_css_class("bar-island-balance-slot-start")
      const spacer = isStart ? child.get_first_child() : child.get_last_child()
      if (spacer instanceof Gtk.Widget && spacer.has_css_class("bar-island-balance-spacer")) {
        spacers.push(spacer)
      }
    }
    child = child.get_next_sibling()
  }
  return { segments, spacers }
}

// Walk a flat segment list in one direction, skipping hidden entries.
function findVisibleListNeighbor(
  segment: Gtk.Widget,
  list: Gtk.Widget[],
  dir: "next" | "prev",
): Gtk.Widget | undefined {
  const idx = list.indexOf(segment)
  if (idx === -1) return undefined
  const step = dir === "next" ? 1 : -1
  for (let i = idx + step; i >= 0 && i < list.length; i += step) {
    if (list[i].visible) return list[i]
  }
  return undefined
}

// Transfer all edge classes on `from` to the nearest visible neighbor found by
// `findNeighbor`. Records each transfer in `borrowed` for later reclaim.
function transferEdgeClasses(
  from: Gtk.Widget,
  borrowed: BorrowedClass[],
  findNeighbor: (segment: Gtk.Widget, dir: "next" | "prev") => Gtk.Widget | undefined,
) {
  for (const cls of EDGE_CLASSES) {
    if (!from.has_css_class(cls)) continue
    const target = findNeighbor(from, EDGE_CLASS_PROPAGATION_DIR[cls])
    if (target) {
      from.remove_css_class(cls)
      target.add_css_class(cls)
      borrowed.push({ cls, holder: target })
    }
    // No visible neighbor — leave the class on the hiding segment so it
    // can be reclaimed intact when the segment becomes visible again.
  }
}

function reclaimEdgeClasses(to: Gtk.Widget, borrowed: BorrowedClass[]) {
  for (const { cls, holder } of borrowed) {
    holder.remove_css_class(cls)
    to.add_css_class(cls)
  }
  borrowed.length = 0
}

// Typed registry for the SizeGroup attached to each center island pivot element.
// Island.tsx registers when it creates the center element; setupSegmentCollapse reads it
// at realize time to disable balancing when the pivot hides.
const centerGroupSizeGroups = new WeakMap<Gtk.Widget, Gtk.SizeGroup>()

export function registerCenterGroupSizeGroup(centerElement: Gtk.Widget, sizeGroup: Gtk.SizeGroup): void {
  centerGroupSizeGroups.set(centerElement, sizeGroup)
}

// Manages the center group container's visibility and SizeGroup state for the
// multi-widget center case. When all inner segments hide, disables the SizeGroup
// and hides spacers so the balance slots don't leave dead space. Restores on
// first re-show.
export function setupCenterGroupCollapse(
  container: Gtk.Box,
  innerSegments: Gtk.Box[],
  sizeGroup: Gtk.SizeGroup,
  spacers: Gtk.Widget[],
) {
  container.connect("realize", () => {
    const originalMode = sizeGroup.mode
    let collapsed = false

    function update() {
      const allHidden = innerSegments.every(s => !s.visible)
      if (allHidden === collapsed) return
      collapsed = allHidden
      if (allHidden) {
        container.visible = false
        sizeGroup.mode = Gtk.SizeGroupMode.NONE
        for (const s of spacers) s.visible = false
      } else {
        container.visible = true
        sizeGroup.mode = originalMode
        for (const s of spacers) s.visible = true
      }
    }

    for (const seg of innerSegments) {
      seg.connect("notify::visible", update)
    }

    update()
  })
}

function setupSegmentCollapse(segment: Gtk.Box, child: Gtk.Widget) {
  segment.connect("realize", () => {
    const borrowed: BorrowedClass[] = []
    let hide: () => void
    let show: () => void

    const centerIsland = getCenterIsland(segment)

    if (centerIsland) {
      const { segments: allSegments, spacers } = collectCenterIslandLayout(centerIsland)

      if (allSegments.length <= 1) {
        // Only segment in the island: hide the whole container so corner
        // curves don't render with no visible content.
        hide = () => { centerIsland.visible = false }
        show = () => { centerIsland.visible = true }
      } else {
        const findNeighbor = (seg: Gtk.Widget, dir: "next" | "prev") =>
          findVisibleListNeighbor(seg, allSegments, dir)
        hide = () => {
          transferEdgeClasses(segment, borrowed, findNeighbor)
          segment.visible = false
        }
        show = () => {
          reclaimEdgeClasses(segment, borrowed)
          segment.visible = true
        }
      }

      // Center pivot only: when the pivot hides, disable the SizeGroup (so
      // balance slots shrink to content width) and hide the spacers (so they
      // stop pushing content inward toward the gap). Without both, the
      // equal-width constraint leaves dead space between the corner curve and
      // the remaining visible widgets.
      if (segment.get_parent() === centerIsland) {
        const sizeGroup = centerGroupSizeGroups.get(segment)
        const originalMode = sizeGroup?.mode

        if (sizeGroup || spacers.length > 0) {
          const innerHide = hide
          const innerShow = show
          hide = () => {
            innerHide()
            if (sizeGroup) sizeGroup.mode = Gtk.SizeGroupMode.NONE
            for (const s of spacers) s.visible = false
          }
          show = () => {
            innerShow()
            if (sizeGroup && originalMode !== undefined) sizeGroup.mode = originalMode
            for (const s of spacers) s.visible = true
          }
        }
      }
    } else {
      hide = () => {
        transferEdgeClasses(segment, borrowed, findVisibleSegmentNeighbor)
        segment.visible = false
      }
      show = () => {
        reclaimEdgeClasses(segment, borrowed)
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
  centerWidgets: Array<JSX.Element>,
  endWidgets: Array<JSX.Element>,
) {
  const firstCenter = centerWidgets[0]
  const lastCenter = centerWidgets[centerWidgets.length - 1]
  const first = startWidgets[0] ?? firstCenter
  const last = endWidgets[endWidgets.length - 1] ?? lastCenter

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
