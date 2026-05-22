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

const barSlideTransition: Record<BarEdge, Gtk.RevealerTransitionType> = {
  top:    Gtk.RevealerTransitionType.SLIDE_DOWN,
  bottom: Gtk.RevealerTransitionType.SLIDE_UP,
  left:   Gtk.RevealerTransitionType.SLIDE_RIGHT,
  right:  Gtk.RevealerTransitionType.SLIDE_LEFT,
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
  const centerAnchor = resolvedBarConfiguration.layout.center.anchor
    ? renderWidget(resolvedBarConfiguration.layout.center.anchor)
    : null
  const centerEndWidgets = resolvedBarConfiguration.layout.center.end.map(renderWidget)
  const endWidgets = resolvedBarConfiguration.layout.end.map(renderWidget)
  const hasCenterIsland = centerAnchor !== null || centerStartWidgets.length > 0 || centerEndWidgets.length > 0

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
        }}
      >
        <revealer
          revealChild={controller.contentRevealed}
          transitionType={barSlideTransition[placement.edge]}
          transitionDuration={REVEAL_DURATION}
          $={(self: Gtk.Revealer) => {
            self.connect("notify::child-revealed", () => {
              if (!self.childRevealed) controller.onRevealAnimationComplete()
            })
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
                anchor={centerAnchor ?? undefined}
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
        </revealer>
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
