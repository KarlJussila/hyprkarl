import { Gtk } from "ags/gtk4"
import {
  createCenterLeftCornerCurve,
  createCenterRightCornerCurve,
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
  side: "left" | "right"
  children?: JSX.Element | Array<JSX.Element>
}

type CenterIslandProps = BaseProps & {
  left?: JSX.Element | Array<JSX.Element>
  anchor: JSX.Element
  right?: JSX.Element | Array<JSX.Element>
  leftCorner?: JSX.Element
  rightCorner?: JSX.Element
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
      {side === "right" && cornerCurve}
      {wrappedChildren}
      {side === "left" && cornerCurve}
    </box>
  )
}

function renderCenterIsland({
  left,
  anchor,
  right,
  leftCorner = createCenterLeftCornerCurve(),
  rightCorner = createCenterRightCornerCurve(),
  class: className,
  cssName,
  halign,
  hexpand,
}: CenterIslandProps) {
  const sideSizeGroup = new Gtk.SizeGroup({ mode: Gtk.SizeGroupMode.HORIZONTAL })
  const leftWidgets = wrapIslandEntries(normalizeChildren(left))
  const centeredAnchor = wrapIslandEntry(anchor)
  const rightWidgets = wrapIslandEntries(normalizeChildren(right))

  markCenteredIslandEdges(leftWidgets, centeredAnchor, rightWidgets)

  const leftSide = createBalancedSide({
    side: "start",
    widgets: leftWidgets,
    corner: leftCorner,
  })
  const rightSide = createBalancedSide({
    side: "end",
    widgets: rightWidgets,
    corner: rightCorner,
  })

  sideSizeGroup.add_widget(leftSide)
  sideSizeGroup.add_widget(rightSide)

  return (
    <box
      class={islandClassName(className)}
      cssName={cssName}
      halign={halign}
      hexpand={hexpand}
    >
      {leftSide}
      {centeredAnchor}
      {rightSide}
    </box>
  )
}

export default function Island(props: IslandProps) {
  if (isCenterIsland(props)) {
    return renderCenterIsland(props)
  }

  return renderOuterIsland(props)
}
