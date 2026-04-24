import { Gtk } from "ags/gtk4"

export type DropdownAlign = "start" | "center" | "end"
export type DropdownSize = { width: number; height: number }
export type DropdownPosition = { x: number; y: number; edgeClass: string }

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

function frameSnapClass({
  gap,
  x,
  maxX,
}: {
  gap: number
  x: number
  maxX: number
}) {
  if (gap <= 0 && x === 0) {
    return "snapped-left"
  }

  if (gap <= 0 && x === maxX) {
    return "snapped-right"
  }

  return ""
}

export function computeDropdownPosition({
  align,
  anchorAllocation,
  anchorX,
  anchorY,
  dropdownSize,
  gap,
  monitorWidth,
  monitorHeight,
}: {
  align: DropdownAlign
  anchorAllocation: Gtk.Allocation
  anchorX: number
  anchorY: number
  dropdownSize: DropdownSize
  gap: number
  monitorWidth: number
  monitorHeight: number
}) {
  const unclampedX = alignDropdownX({
    align,
    anchorX,
    anchorWidth: anchorAllocation.width,
    dropdownWidth: dropdownSize.width,
  })
  const unclampedY = anchorY + anchorAllocation.height + gap

  const maxX = Math.max(0, monitorWidth - dropdownSize.width)
  const maxY = Math.max(0, monitorHeight - dropdownSize.height)

  const x = Math.round(Math.max(0, Math.min(unclampedX, maxX)))
  const y = Math.round(Math.max(0, Math.min(unclampedY, maxY)))

  return {
    x,
    y,
    edgeClass: frameSnapClass({ gap, x, maxX }),
  } satisfies DropdownPosition
}
