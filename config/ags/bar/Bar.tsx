import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import {
  fallbackBarEdge,
  formatBarConfigError,
  isBarConfigError,
} from "./configError"
import layoutConfig from "./config/layout.config"
import widgetDefinitions from "./config/widgets.config"
import type { ResolvedBarConfiguration } from "./configuration"
import ConfigErrorBar from "./layout/ConfigErrorBar"
import Island from "./layout/Island"
import { createBarPlacement, placementClasses } from "./layout/placement"
import { renderBarWidget } from "./widgets/registry"
import { normalizeBarConfiguration } from "./widgets/registry.shared"

function ResolvedBar({
  gdkmonitor,
  resolvedBarConfiguration,
}: {
  gdkmonitor: Gdk.Monitor
  resolvedBarConfiguration: ResolvedBarConfiguration
}) {
  const placement = createBarPlacement(resolvedBarConfiguration.edge)
  const verticalIslandSizeGroup = placement.isVertical
    ? new Gtk.SizeGroup({ mode: Gtk.SizeGroupMode.HORIZONTAL })
    : null

  function renderWidget(widgetId: string) {
    const widgetConfig = resolvedBarConfiguration.widgets[widgetId]

    return renderBarWidget({
      id: widgetId,
      config: widgetConfig,
      placement,
      monitor: gdkmonitor,
    })
  }

  const startWidgets = resolvedBarConfiguration.layout.start.map(renderWidget)
  const centerStartWidgets = resolvedBarConfiguration.layout.center.start.map(renderWidget)
  const centerAnchor = renderWidget(resolvedBarConfiguration.layout.center.anchor)
  const centerEndWidgets = resolvedBarConfiguration.layout.center.end.map(renderWidget)
  const endWidgets = resolvedBarConfiguration.layout.end.map(renderWidget)

  return (
    <window
      visible
      name="bar"
      class={`Bar ${placementClasses(placement)}`}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={placement.window.anchor}
      application={app}
    >
      <centerbox
        cssName="centerbox"
        class={`bar-layout ${placementClasses(placement)}`}
        orientation={placement.layoutOrientation}
      >
        <Island
          $type="start"
          $={(self) => verticalIslandSizeGroup?.add_widget(self)}
          class="bar-start"
          placement={placement}
          side="start"
          halign={placement.island.start.halign}
          valign={placement.island.start.valign}
          hexpand={placement.island.start.hexpand}
          vexpand={placement.island.start.vexpand}
        >
          {startWidgets}
        </Island>

        <Island
          $type="center"
          $={(self) => verticalIslandSizeGroup?.add_widget(self)}
          class="bar-center"
          cssName="box"
          placement={placement}
          halign={placement.island.center.halign}
          valign={placement.island.center.valign}
          hexpand={placement.island.center.hexpand}
          vexpand={placement.island.center.vexpand}
          start={centerStartWidgets}
          anchor={centerAnchor}
          end={centerEndWidgets}
        />

        <Island
          $type="end"
          $={(self) => verticalIslandSizeGroup?.add_widget(self)}
          class="bar-end"
          placement={placement}
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
    const resolvedBarConfiguration = normalizeBarConfiguration(layoutConfig, widgetDefinitions)

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
