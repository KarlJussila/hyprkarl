import { Gtk } from "ags/gtk4"
import { type BarEdge, type FlyoutAlign } from "../../configuration"

export type FlyoutSize = { width: number; height: number }
export type FlyoutPosition = { x: number; y: number; edgeClass: string }
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

function frameSnapClass({
  edge,
  gap,
  x,
  y,
  maxX,
  maxY,
}: {
  edge: BarEdge
  gap: number
  x: number
  y: number
  maxX: number
  maxY: number
}) {
  if (gap > 0) return ""

  if ((edge === "top" || edge === "bottom") && x === 0) {
    return "snapped-left"
  }

  if ((edge === "top" || edge === "bottom") && x === maxX) {
    return "snapped-right"
  }

  if ((edge === "left" || edge === "right") && y === 0) {
    return "snapped-top"
  }

  if ((edge === "left" || edge === "right") && y === maxY) {
    return "snapped-bottom"
  }

  return ""
}

export function computeFlyoutPosition({
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
  const unclampedX = edge === "left"
    ? anchorX + anchorWidth + gap
    : edge === "right"
      ? anchorX - flyoutSize.width - gap
      : alignFlyoutX({
          align,
          anchorX,
          anchorWidth,
          flyoutWidth: flyoutSize.width,
        })
  const unclampedY = edge === "top"
    ? anchorY + anchorHeight + gap
    : edge === "bottom"
      ? anchorY - flyoutSize.height - gap
      : alignFlyoutY({
          align,
          anchorY,
          anchorHeight,
          flyoutHeight: flyoutSize.height,
        })

  const maxX = Math.max(0, monitorWidth - flyoutSize.width)
  const maxY = Math.max(0, monitorHeight - flyoutSize.height)
  const x = Math.round(Math.max(0, Math.min(unclampedX, maxX)))
  const y = Math.round(Math.max(0, Math.min(unclampedY, maxY)))

  return {
    x,
    y,
    edgeClass: frameSnapClass({ edge, gap, x, y, maxX, maxY }),
  } satisfies FlyoutPosition
}
