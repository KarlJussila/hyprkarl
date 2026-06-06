import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import { createEffect, onCleanup } from "ags"
import layoutConfig from "./config/layout.config"
import widgetDefinitions from "./config/widgets.config"
import type { BarEdge, BarLayoutConfig, ResolvedIslandCorners } from "./types"
import { createHotzoneWindow } from "./autohide/hotzoneWindow"
import { flyoutLocked } from "./autohide/flyoutLock"
import { REVEAL_DURATION, createBarVisibilityController } from "./autohide/barVisibilityController"
import { registerBarCliHandler } from "./autohide/barCliHandler"
import ConfigErrorBar from "./layout/ConfigErrorBar"
import Island from "./layout/Island"
import { createBarPlacement, windowMarginsForEdge, placementClasses } from "./layout/placement"
import { widgets, assertWidgetsExist, type WidgetDefinition, type WidgetDefinitions } from "./widgets/index.ts"

const easeInOut = (t: number) =>
  t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2

const edgeMargin: Record<BarEdge, { get: (w: Astal.Window) => number; set: (w: Astal.Window, v: number) => void }> = {
  top:    { get: (w) => w.marginTop,    set: (w, v) => { w.marginTop    = v } },
  bottom: { get: (w) => w.marginBottom, set: (w, v) => { w.marginBottom = v } },
  left:   { get: (w) => w.marginLeft,   set: (w, v) => { w.marginLeft   = v } },
  right:  { get: (w) => w.marginRight,  set: (w, v) => { w.marginRight  = v } },
}

function isBarEdge(value: unknown): value is BarEdge {
  return value === "top" || value === "bottom" || value === "left" || value === "right"
}

function fallbackBarEdge(value: unknown): BarEdge {
  return isBarEdge(value) ? value : "top"
}

function renderWidget(
  def: WidgetDefinition,
  id: string,
  placement: ReturnType<typeof createBarPlacement>,
  monitor: Gdk.Monitor,
) {
  const entry = widgets[def.kind]
  // The `as any` here is a deliberate single point of variance: TS can't see
  // that `def.kind` discriminates which component to call with which config.
  const Component = entry.Component as (props: any) => JSX.Element
  const { kind: _kind, ...config } = def
  return <Component id={id} config={config} placement={placement} monitor={monitor} />
}

function ResolvedBar({
  gdkmonitor,
  layout,
  definitions,
}: {
  gdkmonitor: Gdk.Monitor
  layout: BarLayoutConfig
  definitions: WidgetDefinitions
}) {
  const edge = layout.edge
  const corners: ResolvedIslandCorners = {
    screenOuter: layout.corners?.screenOuter ?? "round",
    screenInner: layout.corners?.screenInner ?? "round",
    contentOuter: layout.corners?.contentOuter ?? "round",
    contentInner: layout.corners?.contentInner ?? "round",
  }
  const borders = {
    screen: layout.borders?.screen ?? true,
    content: layout.borders?.content ?? true,
    outer: layout.borders?.outer ?? true,
    inner: layout.borders?.inner ?? true,
  }
  const dividers = layout.dividers ?? true
  const layoutClasses = [
    borders.screen && "border-screen",
    borders.content && "border-content",
    borders.outer && "border-outer",
    borders.inner && "border-inner",
    dividers && "dividers",
    corners.screenOuter === "round" && "round-screen-outer",
    corners.screenInner === "round" && "round-screen-inner",
    corners.contentOuter === "round" && "round-content-outer",
    corners.contentInner === "round" && "round-content-inner",
  ].filter(Boolean).join(" ")
  const autohide = layout.autohide ?? false
  const exclusive = layout.exclusive ?? !autohide

  const rawMargin = layout.margin ?? 0
  const margin = typeof rawMargin === "number"
    ? { screen: rawMargin, outer: rawMargin, content: rawMargin }
    : { screen: rawMargin.screen ?? 0, outer: rawMargin.outer ?? 0, content: rawMargin.content ?? 0 }
  const configMargins = windowMarginsForEdge(edge, margin)
  // The gap is applied as window padding (not a window margin): a widget's margin
  // is outside its input region, so a pointer resting in a margin gap reads as
  // "off the bar" and autohide retracts it; padding is part of the surface and is
  // hit-tested, and it's also counted in the exclusive zone, so it reserves space.
  const paddingCss = `window { padding: ${configMargins.top}px ${configMargins.right}px ${configMargins.bottom}px ${configMargins.left}px; }`
  // Revealed resting position of the animated docked-edge margin; the gap itself
  // is padding, so the bar sits flush (0) and slides to -barSize to hide.
  const configEdgeMargin = 0

  const placement = createBarPlacement(edge, configMargins)
  const islandCrossAxisSizeGroup = new Gtk.SizeGroup({
    mode: placement.isVertical
      ? Gtk.SizeGroupMode.HORIZONTAL
      : Gtk.SizeGroupMode.VERTICAL,
  })

  const controller = createBarVisibilityController({
    autohide,
    exclusive,
    flyoutOpen: flyoutLocked,
  })
  onCleanup(registerBarCliHandler(controller))

  createHotzoneWindow({ edge: placement.edge, gdkmonitor, controller })

  const renderById = (id: string) => renderWidget(definitions[id]!, id, placement, gdkmonitor)

  const startWidgets = layout.start.map(renderById)
  const centerStartWidgets = layout.center.start.map(renderById)
  const centerWidgets = layout.center.center.map(renderById)
  const centerEndWidgets = layout.center.end.map(renderById)
  const endWidgets = layout.end.map(renderById)
  const hasCenterIsland = centerWidgets.length > 0 || centerStartWidgets.length > 0 || centerEndWidgets.length > 0

  return (
    <window
        name="bar"
        class={`Bar bar-shell ${placementClasses(placement)}`}
        css={paddingCss}
        gdkmonitor={gdkmonitor}
        visible={controller.windowVisible}
        anchor={placement.window.anchor}
        application={app}
        $={(self: Astal.Window) => {
          const motion = new Gtk.EventControllerMotion()
          motion.connect("enter", () => controller.onPointerEnter())
          motion.connect("leave", () => controller.onPointerLeaveBar())
          self.add_controller(motion)

          createEffect(() => {
            const excl = controller.exclusivity()
            if (excl === Astal.Exclusivity.EXCLUSIVE) {
              // Toggle IGNORE→EXCLUSIVE to force the compositor to recalculate reserved space.
              self.set_exclusivity(Astal.Exclusivity.IGNORE)
            }
            self.set_exclusivity(excl)
          })

          const getMargin = () => edgeMargin[placement.edge].get(self)
          const setMargin = (v: number) => edgeMargin[placement.edge].set(self, v)
          // get_width/get_height report the content box (CSS padding excluded), so
          // add the docked-axis padding to retract the whole surface when hiding.
          const dockedPadding = placement.isVertical
            ? configMargins.left + configMargins.right
            : configMargins.top + configMargins.bottom
          const getBarSize = () => (placement.isVertical ? self.get_width() : self.get_height()) + dockedPadding

          let tickId = 0
          let animFrom = 0
          let animTo = 0
          let animStartTime = 0

          const startAnimation = (to: number) => {
            if (tickId === 0 && getMargin() === to) return
            if (tickId) self.remove_tick_callback(tickId)
            animFrom = getMargin()
            animTo = to
            animStartTime = 0

            tickId = self.add_tick_callback((_: Gtk.Widget, clock: Gdk.FrameClock) => {
              const now = clock.get_frame_time() / 1000
              if (animStartTime === 0) animStartTime = now
              const t = Math.min((now - animStartTime) / REVEAL_DURATION, 1)
              setMargin(animFrom + (animTo - animFrom) * easeInOut(t))
              if (t >= 1) { tickId = 0; return false }
              return true
            })
          }

          createEffect(() => {
            if (controller.contentRevealed()) {
              startAnimation(configEdgeMargin)
            } else {
              startAnimation(-Math.max(getBarSize(), 1))
            }
          })

          onCleanup(() => { if (tickId) self.remove_tick_callback(tickId) })
        }}
      >
      <centerbox
        cssName="centerbox"
        class={`bar-layout bar-layout-root ${placementClasses(placement)}${layoutClasses ? ` ${layoutClasses}` : ""}`}
        orientation={placement.layoutOrientation}
      >
        <Island
          $type="start"
          $={(self) => islandCrossAxisSizeGroup.add_widget(self)}
          class="bar-island-start"
          placement={placement}
          corners={corners}
          side="start"
          halign={placement.island.start.halign}
          valign={placement.island.start.valign}
          hexpand={placement.island.start.hexpand}
          vexpand={placement.island.start.vexpand}
        >
          {startWidgets}
        </Island>

        {hasCenterIsland && (
          <Island
            $type="center"
            $={(self) => islandCrossAxisSizeGroup.add_widget(self)}
            class="bar-island-main"
            cssName="box"
            placement={placement}
            corners={corners}
            halign={placement.island.center.halign}
            valign={placement.island.center.valign}
            hexpand={placement.island.center.hexpand}
            vexpand={placement.island.center.vexpand}
            start={centerStartWidgets}
            center={centerWidgets}
            end={centerEndWidgets}
          />
        )}

        <Island
          $type="end"
          $={(self) => islandCrossAxisSizeGroup.add_widget(self)}
          class="bar-island-end"
          placement={placement}
          corners={corners}
          side="end"
          halign={placement.island.end.halign}
          valign={placement.island.end.valign}
          hexpand={placement.island.end.hexpand}
          vexpand={placement.island.end.vexpand}
        >
          {endWidgets}
        </Island>
      </centerbox>
    </window>
  )
}

export default function Bar(gdkmonitor: Gdk.Monitor) {
  try {
    assertWidgetsExist(layoutConfig as BarLayoutConfig, widgetDefinitions as WidgetDefinitions)

    return (
      <ResolvedBar
        gdkmonitor={gdkmonitor}
        layout={layoutConfig as BarLayoutConfig}
        definitions={widgetDefinitions as WidgetDefinitions}
      />
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    console.error(`Bar config error: ${message}`)

    return (
      <ConfigErrorBar
        edge={fallbackBarEdge((layoutConfig as { edge?: unknown }).edge)}
        message={message}
        monitor={gdkmonitor}
      />
    )
  }
}
