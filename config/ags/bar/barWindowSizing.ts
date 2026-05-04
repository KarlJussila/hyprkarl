import { Astal, Gtk } from "ags/gtk4"
import { type BarOrientation } from "./barPlacement"

export function measureWidgetWidth(widget: Gtk.Widget) {
  const allocation = widget.get_allocation()
  if (allocation.width > 0) {
    return allocation.width
  }

  const [, naturalWidth] = widget.measure(Gtk.Orientation.HORIZONTAL, -1)
  return naturalWidth
}

export function requestBarWindowRelayout(widget: Gtk.Widget, orientation: BarOrientation) {
  widget.queue_resize()

  let parent = widget.get_parent()
  while (parent) {
    parent.queue_resize()
    parent = parent.get_parent()
  }

  const root = widget.get_root()
  if (root instanceof Gtk.Widget) {
    root.queue_resize()
  }

  if (orientation !== "vertical" || !(root instanceof Astal.Window)) {
    return
  }

  const currentExclusivity = root.exclusivity
  if (currentExclusivity !== Astal.Exclusivity.EXCLUSIVE) {
    return
  }

  root.set_exclusivity(Astal.Exclusivity.IGNORE)
  root.set_exclusivity(currentExclusivity)
}
