import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import { createEffect, onCleanup } from "ags"
import {
  fallbackBarEdge,
  formatBarConfigError,
  isBarConfigError,
} from "./configError"
import layoutConfig from "./config/layout.config"
import widgetDefinitions from "./config/widgets.config"
import type { ResolvedBarConfiguration } from "./configuration"
import { createHotzoneWindow } from "./autohide/hotzoneWindow"
import { flyoutLocked } from "./autohide/flyoutLock"
import { REVEAL_DURATION, createBarVisibilityController } from "./autohide/barVisibilityController"
import { registerBarCliHandler } from "./autohide/barCliHandler"
import ConfigErrorBar from "./layout/ConfigErrorBar"
import Island from "./layout/Island"
import { createBarPlacement, placementClasses } from "./layout/placement"
import type { BarEdge } from "./configuration"
import { renderWidgetByKind } from "./widgets/renderWidgetByKind"
import { resolveBarConfiguration } from "./widgets/resolveBarConfiguration"

const easeInOut = (t: number) =>
  t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2

const edgeMargin: Record<BarEdge, { get: (w: Astal.Window) => number; set: (w: Astal.Window, v: number) => void }> = {
  top:    { get: (w) => w.marginTop,    set: (w, v) => { w.marginTop    = v } },
  bottom: { get: (w) => w.marginBottom, set: (w, v) => { w.marginBottom = v } },
  left:   { get: (w) => w.marginLeft,   set: (w, v) => { w.marginLeft   = v } },
  right:  { get: (w) => w.marginRight,  set: (w, v) => { w.marginRight  = v } },
}

function ResolvedBar({
  gdkmonitor,
  resolvedBarConfiguration,
}: {
  gdkmonitor: Gdk.Monitor
  resolvedBarConfiguration: ResolvedBarConfiguration
}) {
  const placement = createBarPlacement(resolvedBarConfiguration.edge)
  const islandCrossAxisSizeGroup = new Gtk.SizeGroup({
    mode: placement.isVertical
      ? Gtk.SizeGroupMode.HORIZONTAL
      : Gtk.SizeGroupMode.VERTICAL,
  })

  const controller = createBarVisibilityController({
    autohide: resolvedBarConfiguration.autohide,
    exclusive: resolvedBarConfiguration.exclusive,
    flyoutOpen: flyoutLocked,
  })
  onCleanup(registerBarCliHandler(controller))

  createHotzoneWindow({ edge: placement.edge, gdkmonitor, controller })

  function renderWidget(widgetId: string) {
    const widgetConfig = resolvedBarConfiguration.widgets[widgetId]

    return renderWidgetByKind({
      id: widgetId,
      config: widgetConfig,
      placement,
      monitor: gdkmonitor,
    })
  }

  const startWidgets = resolvedBarConfiguration.layout.start.map(renderWidget)
  const centerStartWidgets = resolvedBarConfiguration.layout.center.start.map(renderWidget)
  const centerWidgets = resolvedBarConfiguration.layout.center.center.map(renderWidget)
  const centerEndWidgets = resolvedBarConfiguration.layout.center.end.map(renderWidget)
  const endWidgets = resolvedBarConfiguration.layout.end.map(renderWidget)
  const hasCenterIsland = centerWidgets.length > 0 || centerStartWidgets.length > 0 || centerEndWidgets.length > 0

  return (
    <window
        name="bar"
        class={`Bar bar-shell ${placementClasses(placement)}`}
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
          const getBarSize = () => placement.isVertical ? self.get_width() : self.get_height()

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
              startAnimation(0)
            } else {
              startAnimation(-Math.max(getBarSize(), 1))
            }
          })

          onCleanup(() => { if (tickId) self.remove_tick_callback(tickId) })
        }}
      >
      <centerbox
        cssName="centerbox"
        class={`bar-layout bar-layout-root ${placementClasses(placement)}`}
        orientation={placement.layoutOrientation}
      >
        <Island
          $type="start"
          $={(self) => islandCrossAxisSizeGroup.add_widget(self)}
          class="bar-island-start"
          placement={placement}
          showCornerCurves={resolvedBarConfiguration.showCornerCurves}
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
            showCornerCurves={resolvedBarConfiguration.showCornerCurves}
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
          showCornerCurves={resolvedBarConfiguration.showCornerCurves}
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
    const resolvedBarConfiguration = resolveBarConfiguration(layoutConfig, widgetDefinitions)

    return (
      <ResolvedBar
        gdkmonitor={gdkmonitor}
        resolvedBarConfiguration={resolvedBarConfiguration}
      />
    )
  } catch (error) {
    if (!isBarConfigError(error)) {
      throw error
    }

    console.error(formatBarConfigError(error))

    return (
      <ConfigErrorBar
        edge={fallbackBarEdge((layoutConfig as { edge?: unknown }).edge)}
        error={error}
        monitor={gdkmonitor}
      />
    )
  }
}
