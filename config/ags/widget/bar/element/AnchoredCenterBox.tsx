import { Gtk } from "ags/gtk4"
import CornerCurve from "./CornerCurve"

type Props = {
  start?: JSX.Element | Array<JSX.Element>
  anchor: JSX.Element
  end?: JSX.Element | Array<JSX.Element>
  startEdge?: JSX.Element
  endEdge?: JSX.Element
  class?: string
  cssName?: string
  halign?: Gtk.Align
  hexpand?: boolean
}

function toArray(children?: JSX.Element | Array<JSX.Element>) {
  return children === undefined ? [] : Array.isArray(children) ? children : [children]
}

function keepNaturalWidth(widget: JSX.Element) {
  if (widget instanceof Gtk.Widget) {
    widget.hexpand = false
  }
}

function markIslandEdges(start: Array<JSX.Element>, anchor: JSX.Element, end: Array<JSX.Element>) {
  const first = start[0] ?? anchor
  const last = end[end.length - 1] ?? anchor

  if (first instanceof Gtk.Widget) {
    first.add_css_class("island-start")
  }

  if (last instanceof Gtk.Widget) {
    last.add_css_class("island-end")
  }
}

export default function AnchoredCenterBox({
  start,
  anchor,
  end,
  startEdge = <CornerCurve position="top-right" size={12} radius={4} class="border-curve" />,
  endEdge = <CornerCurve position="top-left" size={12} radius={4} class="border-curve" />,
  class: className,
  cssName,
  halign,
  hexpand,
}: Props) {
  const sideSizeGroup = new Gtk.SizeGroup({ mode: Gtk.SizeGroupMode.HORIZONTAL })
  const startWidgets = toArray(start)
  const endWidgets = toArray(end)
  const islandWidgets = [...startWidgets, anchor, ...endWidgets]

  islandWidgets.forEach(keepNaturalWidth)
  markIslandEdges(startWidgets, anchor, endWidgets)

  // Match the side slots so the anchor child stays visually centered.
  const startSlot = (
    <box class="balance-slot balance-start">
      <box class="balance-spacer" hexpand />
      <box class="balance-content" hexpand={false}>
        {startEdge}
        {startWidgets}
      </box>
    </box>
  ) as Gtk.Box

  const endSlot = (
    <box class="balance-slot balance-end">
      <box class="balance-content" hexpand={false}>
        {endWidgets}
        {endEdge}
      </box>
      <box class="balance-spacer" hexpand />
    </box>
  ) as Gtk.Box

  sideSizeGroup.add_widget(startSlot)
  sideSizeGroup.add_widget(endSlot)

  const balancedBox = (
    <box
      class={className}
      cssName={cssName}
      halign={halign}
      hexpand={hexpand}
    >
      {startSlot}
      {anchor}
      {endSlot}
    </box>
  ) as Gtk.Box

  Object.assign(balancedBox, { sideSizeGroup })

  return balancedBox
}
