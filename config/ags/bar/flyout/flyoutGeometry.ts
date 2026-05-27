import { Gtk } from "ags/gtk4"
import { type BarEdge } from "../types"
import { type FlyoutAlign } from "./flyoutTypes"

export type FlyoutSize = { width: number; height: number }
export type FlyoutMargins = { nearEdge: number; crossAxis: number; edgeClass: string }
export type WidgetBounds = { x: number; y: number; width: number; height: number }

export function measureWidget(widget: Gtk.Widget | null): FlyoutSize {
  if (!widget) {
    return { width: 0, height: 0 }
  }

  const [, naturalWidth] = widget.measure(Gtk.Orientation.HORIZONTAL, -1)
  const [, naturalHeight] = widget.measure(Gtk.Orientation.VERTICAL, naturalWidth)

  return {
    width: naturalWidth,
    height: naturalHeight,
  }
}

export function rootRelativeAnchorBounds({
  anchorWidget,
  rootWidget,
}: {
  anchorWidget: Gtk.Widget
  rootWidget: Gtk.Widget
}) {
  const [resolved, bounds] = anchorWidget.compute_bounds(rootWidget)
  if (!resolved) {
    return null
  }

  return {
    x: bounds.origin.x,
    y: bounds.origin.y,
    width: bounds.size.width,
    height: bounds.size.height,
  } satisfies WidgetBounds
}

function alignFlyoutX({
  align,
  anchorX,
  anchorWidth,
  flyoutWidth,
}: {
  align: FlyoutAlign
  anchorX: number
  anchorWidth: number
  flyoutWidth: number
}) {
  switch (align) {
    case "start":
      return anchorX
    case "end":
      return anchorX + anchorWidth - flyoutWidth
    case "center":
    default:
      return anchorX + ((anchorWidth - flyoutWidth) / 2)
  }
}

function alignFlyoutY({
  align,
  anchorY,
  anchorHeight,
  flyoutHeight,
}: {
  align: FlyoutAlign
  anchorY: number
  anchorHeight: number
  flyoutHeight: number
}) {
  switch (align) {
    case "start":
      return anchorY
    case "end":
      return anchorY + anchorHeight - flyoutHeight
    case "center":
    default:
      return anchorY + ((anchorHeight - flyoutHeight) / 2)
  }
}

function edgeSnapClass({
  edge,
  gap,
  crossAxis,
  maxCrossAxis,
}: {
  edge: BarEdge
  gap: number
  crossAxis: number
  maxCrossAxis: number
}) {
  if (gap > 0) return ""

  if ((edge === "top" || edge === "bottom") && crossAxis === 0) return "snapped-left"
  if ((edge === "top" || edge === "bottom") && crossAxis === maxCrossAxis) return "snapped-right"
  if ((edge === "left" || edge === "right") && crossAxis === 0) return "snapped-top"
  if ((edge === "left" || edge === "right") && crossAxis === maxCrossAxis) return "snapped-bottom"

  return ""
}

export function computeFlyoutMargins({
  edge,
  align,
  anchorWidth,
  anchorHeight,
  anchorX,
  anchorY,
  flyoutSize,
  gap,
  monitorWidth,
  monitorHeight,
}: {
  edge: BarEdge
  align: FlyoutAlign
  anchorWidth: number
  anchorHeight: number
  anchorX: number
  anchorY: number
  flyoutSize: FlyoutSize
  gap: number
  monitorWidth: number
  monitorHeight: number
}) {
  // Distance from the bar edge to the flyout's near side — no flyout size needed.
  const nearEdge = Math.round(
    edge === "top" ? anchorY + anchorHeight + gap
    : edge === "bottom" ? monitorHeight - anchorY + gap
    : edge === "left" ? anchorX + anchorWidth + gap
    : monitorWidth - anchorX + gap,
  )

  // Position along the bar — flyout cross-size needed only for edge clamping.
  const isHorizontalBar = edge === "top" || edge === "bottom"

  const rawCrossAxis = isHorizontalBar
    ? alignFlyoutX({ align, anchorX, anchorWidth, flyoutWidth: flyoutSize.width })
    : alignFlyoutY({ align, anchorY, anchorHeight, flyoutHeight: flyoutSize.height })

  const maxCrossAxis = isHorizontalBar
    ? Math.max(0, monitorWidth - flyoutSize.width)
    : Math.max(0, monitorHeight - flyoutSize.height)

  const crossAxis = Math.round(Math.max(0, Math.min(rawCrossAxis, maxCrossAxis)))

  return {
    nearEdge,
    crossAxis,
    edgeClass: edgeSnapClass({ edge, gap, crossAxis, maxCrossAxis }),
  } satisfies FlyoutMargins
}
