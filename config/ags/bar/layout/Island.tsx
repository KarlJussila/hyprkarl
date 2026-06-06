import { Gtk } from "ags/gtk4"
import { type BarPlacement, placementClasses } from "./placement"
import type { ResolvedIslandCorners } from "../types"
import {
  createCenterEndCornerCurve,
  createCenterStartCornerCurve,
  createOuterCornerCurve,
  markCenteredGroupEdges,
  markCenteredIslandEdges,
  markOuterIslandEdges,
  normalizeChildren,
  registerCenterGroupSizeGroup,
  setupCenterGroupCollapse,
  wrapIslandEntries,
  wrapIslandEntry,
} from "./islandLayout"

type BaseProps = {
  $type?: string
  $?: (widget: Gtk.Box) => void
  class?: string
  cssName?: string
  placement: BarPlacement
  corners: ResolvedIslandCorners
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
  center?: Array<JSX.Element>
  end?: JSX.Element | Array<JSX.Element>
  startCorner?: JSX.Element
  endCorner?: JSX.Element
}

type IslandProps = OuterIslandProps | CenterIslandProps

function islandClassName(className?: string) {
  return className ? `${className} bar-island` : "bar-island"
}

function isCenterIsland(props: IslandProps): props is CenterIslandProps {
  return "start" in props || "center" in props || "end" in props
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
  corner: JSX.Element | null
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
  corners,
  $: setup,
  halign,
  hexpand,
  valign,
  vexpand,
}: OuterIslandProps) {
  const wrappedChildren = wrapIslandEntries(normalizeChildren(children), placement)
  markOuterIslandEdges(wrappedChildren, side)
  // A start/end island's single curve sits on its inner (gap-facing) screen
  // corner — same screen-inner corner the center island curves.
  const cornerCurve = corners.screenInner === "curve" ? createOuterCornerCurve(placement, side) : null

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
  center,
  end,
  placement,
  corners,
  startCorner,
  endCorner,
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
  // Both ends of the center island are screen-inner corners.
  const curveCenter = corners.screenInner === "curve"
  const resolvedStartCorner = startCorner ?? (
    curveCenter ? createCenterStartCornerCurve(placement) : null
  )
  const resolvedEndCorner = endCorner ?? (
    curveCenter ? createCenterEndCornerCurve(placement) : null
  )

  if (!center || center.length === 0) {
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
        {resolvedStartCorner}
        {centeredWidgets}
        {resolvedEndCorner}
      </box>
    )
  }

  const sideSizeGroup = new Gtk.SizeGroup({
    mode: placement.isVertical
      ? Gtk.SizeGroupMode.VERTICAL
      : Gtk.SizeGroupMode.HORIZONTAL,
  })

  const startSide = createBalancedSide({
    placement,
    side: "start",
    widgets: startWidgets,
    corner: resolvedStartCorner,
  })
  const endSide = createBalancedSide({
    placement,
    side: "end",
    widgets: endWidgets,
    corner: resolvedEndCorner,
  })

  sideSizeGroup.add_widget(startSide)
  sideSizeGroup.add_widget(endSide)

  let centeredElement: Gtk.Box
  let centerSegments: Gtk.Box[]

  if (center.length === 1) {
    const seg = wrapIslandEntry(center[0], placement)
    registerCenterGroupSizeGroup(seg, sideSizeGroup)
    centeredElement = seg
    centerSegments = [seg]
  } else {
    const segs = center.map(w => wrapIslandEntry(w, placement))
    const groupBox = (
      <box
        class="bar-island-center-group"
        orientation={placement.layoutOrientation}
      >
        {segs}
      </box>
    ) as Gtk.Box
    registerCenterGroupSizeGroup(groupBox, sideSizeGroup)
    centeredElement = groupBox
    centerSegments = segs

    const spacers: Gtk.Widget[] = []
    const startSpacer = startSide.get_first_child()
    const endSpacer = endSide.get_last_child()
    if (startSpacer instanceof Gtk.Widget && startSpacer.has_css_class("bar-island-balance-spacer")) spacers.push(startSpacer)
    if (endSpacer instanceof Gtk.Widget && endSpacer.has_css_class("bar-island-balance-spacer")) spacers.push(endSpacer)
    setupCenterGroupCollapse(groupBox, segs, sideSizeGroup, spacers)
  }

  markCenteredIslandEdges(startWidgets, centerSegments, endWidgets)

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
      {centeredElement}
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
