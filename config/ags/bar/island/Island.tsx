import { Gtk } from "ags/gtk4"
import {
  createCenterEndCornerCurve,
  createCenterStartCornerCurve,
  createOuterCornerCurve,
  markCenteredIslandEdges,
  markOuterIslandEdges,
  normalizeChildren,
  wrapIslandEntries,
  wrapIslandEntry,
} from "./islandLayout"

type BaseProps = {
  class?: string
  cssName?: string
  halign?: Gtk.Align
  hexpand?: boolean
}

type OuterIslandProps = BaseProps & {
  side: "start" | "end"
  children?: JSX.Element | Array<JSX.Element>
}

type CenterIslandProps = BaseProps & {
  start?: JSX.Element | Array<JSX.Element>
  anchor: JSX.Element
  end?: JSX.Element | Array<JSX.Element>
  startCorner?: JSX.Element
  endCorner?: JSX.Element
}

type IslandProps = OuterIslandProps | CenterIslandProps

function islandClassName(className?: string) {
  return className ? `${className} island` : "island"
}

function isCenterIsland(props: IslandProps): props is CenterIslandProps {
  return "anchor" in props
}

function createBalancedSide({
  side,
  widgets,
  corner,
}: {
  side: "start" | "end"
  widgets: Array<JSX.Element>
  corner: JSX.Element
}) {
  const content = side === "start"
    ? (
        <box class="balance-content" hexpand={false}>
          {corner}
          {widgets}
        </box>
      )
    : (
        <box class="balance-content" hexpand={false}>
          {widgets}
          {corner}
        </box>
      )

  return (
    <box class={`balance-slot balance-${side}`}>
      {side === "start" && <box class="balance-spacer" hexpand />}
      {content}
      {side === "end" && <box class="balance-spacer" hexpand />}
    </box>
  ) as Gtk.Box
}

function renderOuterIsland({
  side,
  children,
  class: className,
  cssName,
  halign,
  hexpand,
}: OuterIslandProps) {
  const wrappedChildren = wrapIslandEntries(normalizeChildren(children))
  markOuterIslandEdges(wrappedChildren, side)
  const cornerCurve = createOuterCornerCurve(side)

  return (
    <box
      class={islandClassName(className)}
      cssName={cssName}
      halign={halign}
      hexpand={hexpand}
    >
      {side === "end" && cornerCurve}
      {wrappedChildren}
      {side === "start" && cornerCurve}
    </box>
  )
}

function renderCenterIsland({
  start,
  anchor,
  end,
  startCorner = createCenterStartCornerCurve(),
  endCorner = createCenterEndCornerCurve(),
  class: className,
  cssName,
  halign,
  hexpand,
}: CenterIslandProps) {
  const sideSizeGroup = new Gtk.SizeGroup({ mode: Gtk.SizeGroupMode.HORIZONTAL })
  const startWidgets = wrapIslandEntries(normalizeChildren(start))
  const centeredAnchor = wrapIslandEntry(anchor)
  const endWidgets = wrapIslandEntries(normalizeChildren(end))

  markCenteredIslandEdges(startWidgets, centeredAnchor, endWidgets)

  const startSide = createBalancedSide({
    side: "start",
    widgets: startWidgets,
    corner: startCorner,
  })
  const endSide = createBalancedSide({
    side: "end",
    widgets: endWidgets,
    corner: endCorner,
  })

  sideSizeGroup.add_widget(startSide)
  sideSizeGroup.add_widget(endSide)

  return (
    <box
      class={islandClassName(className)}
      cssName={cssName}
      halign={halign}
      hexpand={hexpand}
    >
      {startSide}
      {centeredAnchor}
      {endSide}
    </box>
  )
}

export default function Island(props: IslandProps) {
  if (isCenterIsland(props)) {
    return renderCenterIsland(props)
  }

  return renderOuterIsland(props)
}
