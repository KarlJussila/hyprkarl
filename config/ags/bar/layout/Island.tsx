import { Gtk } from "ags/gtk4"
import { type BarPlacement, placementClasses } from "./placement"
import {
  createCenterEndCornerCurve,
  createCenterStartCornerCurve,
  createOuterCornerCurve,
  markCenteredGroupEdges,
  markCenteredIslandEdges,
  markOuterIslandEdges,
  normalizeChildren,
  wrapIslandEntries,
  wrapIslandEntry,
} from "./islandLayout"

type BaseProps = {
  $type?: string
  $?: (widget: Gtk.Box) => void
  class?: string
  cssName?: string
  placement: BarPlacement
  halign?: Gtk.Align
  hexpand?: boolean
  valign?: Gtk.Align
  vexpand?: boolean
}

type OuterIslandProps = BaseProps & {
  side: "start" | "end"
  children?: JSX.Element | Array<JSX.Element>
}

type CenterIslandProps = BaseProps & {
  start?: JSX.Element | Array<JSX.Element>
  anchor?: JSX.Element
  end?: JSX.Element | Array<JSX.Element>
  startCorner?: JSX.Element
  endCorner?: JSX.Element
}

type IslandProps = OuterIslandProps | CenterIslandProps

function islandClassName(className?: string) {
  return className ? `${className} bar-island` : "bar-island"
}

function isCenterIsland(props: IslandProps): props is CenterIslandProps {
  return "start" in props || "anchor" in props || "end" in props
}

function createBalancedSide({
  placement,
  side,
  widgets,
  corner,
}: {
  placement: BarPlacement
  side: "start" | "end"
  widgets: Array<JSX.Element>
  corner: JSX.Element
}) {
  const content = side === "start"
    ? (
        <box
          class="bar-island-balance-content"
          hexpand={false}
          vexpand={false}
          orientation={placement.layoutOrientation}
        >
          {corner}
          {widgets}
        </box>
      )
    : (
        <box
          class="bar-island-balance-content"
          hexpand={false}
          vexpand={false}
          orientation={placement.layoutOrientation}
        >
          {widgets}
          {corner}
        </box>
      )

  return (
    <box
      class={`bar-island-balance-slot bar-island-balance-slot-${side}`}
      orientation={placement.layoutOrientation}
    >
      {side === "start" && (
        <box
          class="bar-island-balance-spacer"
          hexpand={!placement.isVertical}
          vexpand={placement.isVertical}
        />
      )}
      {content}
      {side === "end" && (
        <box
          class="bar-island-balance-spacer"
          hexpand={!placement.isVertical}
          vexpand={placement.isVertical}
        />
      )}
    </box>
  ) as Gtk.Box
}

function renderOuterIsland({
  side,
  children,
  class: className,
  cssName,
  placement,
  $: setup,
  halign,
  hexpand,
  valign,
  vexpand,
}: OuterIslandProps) {
  const wrappedChildren = wrapIslandEntries(normalizeChildren(children), placement)
  markOuterIslandEdges(wrappedChildren, side)
  const cornerCurve = createOuterCornerCurve(placement, side)

  return (
    <box
      class={`${islandClassName(className)} bar-island-outer ${placementClasses(placement)}`}
      cssName={cssName}
      halign={halign}
      valign={valign}
      hexpand={hexpand}
      vexpand={vexpand}
      orientation={placement.layoutOrientation}
      $={setup}
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
  placement,
  startCorner = createCenterStartCornerCurve(placement),
  endCorner = createCenterEndCornerCurve(placement),
  class: className,
  cssName,
  halign,
  hexpand,
  valign,
  vexpand,
  $: setup,
}: CenterIslandProps) {
  const startWidgets = wrapIslandEntries(normalizeChildren(start), placement)
  const endWidgets = wrapIslandEntries(normalizeChildren(end), placement)

  if (!anchor) {
    const centeredWidgets = [...startWidgets, ...endWidgets]
    markCenteredGroupEdges(centeredWidgets)

    return (
      <box
        class={`${islandClassName(className)} bar-island-center ${placementClasses(placement)}`}
        cssName={cssName}
        halign={halign}
        valign={valign}
        hexpand={hexpand}
        vexpand={vexpand}
        orientation={placement.layoutOrientation}
        $={setup}
      >
        {startCorner}
        {centeredWidgets}
        {endCorner}
      </box>
    )
  }

  const sideSizeGroup = new Gtk.SizeGroup({
    mode: placement.isVertical
      ? Gtk.SizeGroupMode.VERTICAL
      : Gtk.SizeGroupMode.HORIZONTAL,
  })
  const centeredAnchor = wrapIslandEntry(anchor, placement)

  markCenteredIslandEdges(startWidgets, centeredAnchor, endWidgets)

  const startSide = createBalancedSide({
    placement,
    side: "start",
    widgets: startWidgets,
    corner: startCorner,
  })
  const endSide = createBalancedSide({
    placement,
    side: "end",
    widgets: endWidgets,
    corner: endCorner,
  })

  sideSizeGroup.add_widget(startSide)
  sideSizeGroup.add_widget(endSide)

  return (
    <box
      class={`${islandClassName(className)} bar-island-center ${placementClasses(placement)}`}
      cssName={cssName}
      halign={halign}
      valign={valign}
      hexpand={hexpand}
      vexpand={vexpand}
      orientation={placement.layoutOrientation}
      $={setup}
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
