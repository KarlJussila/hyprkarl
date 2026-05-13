import { Gtk } from "ags/gtk4"
import { type BarEdge, type DropdownAlign } from "../../configuration"

export type DropdownSize = { width: number; height: number }
export type DropdownPosition = { x: number; y: number; edgeClass: string }
export type WidgetBounds = { x: number; y: number; width: number; height: number }

export function measureWidget(widget: Gtk.Widget | null): DropdownSize {
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

function alignDropdownX({
  align,
  anchorX,
  anchorWidth,
  dropdownWidth,
}: {
  align: DropdownAlign
  anchorX: number
  anchorWidth: number
  dropdownWidth: number
}) {
  switch (align) {
    case "start":
      return anchorX
    case "end":
      return anchorX + anchorWidth - dropdownWidth
    case "center":
    default:
      return anchorX + ((anchorWidth - dropdownWidth) / 2)
  }
}

function alignDropdownY({
  align,
  anchorY,
  anchorHeight,
  dropdownHeight,
}: {
  align: DropdownAlign
  anchorY: number
  anchorHeight: number
  dropdownHeight: number
}) {
  switch (align) {
    case "start":
      return anchorY
    case "end":
      return anchorY + anchorHeight - dropdownHeight
    case "center":
    default:
      return anchorY + ((anchorHeight - dropdownHeight) / 2)
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

export function computeDropdownPosition({
  edge,
  align,
  anchorWidth,
  anchorHeight,
  anchorX,
  anchorY,
  dropdownSize,
  gap,
  monitorWidth,
  monitorHeight,
}: {
  edge: BarEdge
  align: DropdownAlign
  anchorWidth: number
  anchorHeight: number
  anchorX: number
  anchorY: number
  dropdownSize: DropdownSize
  gap: number
  monitorWidth: number
  monitorHeight: number
}) {
  const unclampedX = edge === "left"
    ? anchorX + anchorWidth + gap
    : edge === "right"
      ? anchorX - dropdownSize.width - gap
      : alignDropdownX({
          align,
          anchorX,
          anchorWidth,
          dropdownWidth: dropdownSize.width,
        })
  const unclampedY = edge === "top"
    ? anchorY + anchorHeight + gap
    : edge === "bottom"
      ? anchorY - dropdownSize.height - gap
      : alignDropdownY({
          align,
          anchorY,
          anchorHeight,
          dropdownHeight: dropdownSize.height,
        })

  const maxX = Math.max(0, monitorWidth - dropdownSize.width)
  const maxY = Math.max(0, monitorHeight - dropdownSize.height)
  const x = Math.round(Math.max(0, Math.min(unclampedX, maxX)))
  const y = Math.round(Math.max(0, Math.min(unclampedY, maxY)))

  return {
    x,
    y,
    edgeClass: frameSnapClass({ edge, gap, x, y, maxX, maxY }),
  } satisfies DropdownPosition
}
