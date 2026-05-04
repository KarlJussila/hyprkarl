import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import { createBarPlacement, placementClasses } from "./barPlacement"
import { barEdge, barLayout, type BarWidgetConfig } from "./barConfig"
import Island from "./island/Island"
import HyprkarlMenu from "./widget/HyprkarlMenu"
import Clock from "./widget/time/Clock"
import CaffeineToggle from "./widget/CaffeineToggle"
import Battery from "./widget/battery/Battery"
import Workspaces from "./widget/workspaces/Workspaces"
import Tray from "./widget/tray/Tray"

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const placement = createBarPlacement(barEdge)
  const verticalIslandSizeGroup = placement.isVertical
    ? new Gtk.SizeGroup({ mode: Gtk.SizeGroupMode.HORIZONTAL })
    : null

  function renderWidget(widget: BarWidgetConfig) {
    if (widget === "menu") {
      return <HyprkarlMenu orientation={placement.orientation} />
    }

    if (widget === "workspaces") {
      return <Workspaces orientation={placement.orientation} />
    }

    if (widget === "clock") {
      return <Clock monitor={gdkmonitor} placement={placement} />
    }

    if (widget === "caffeine") {
      return <CaffeineToggle orientation={placement.orientation} />
    }

    if (widget === "battery") {
      return <Battery monitor={gdkmonitor} placement={placement} />
    }

    if (widget === "tray") {
      return <Tray placement={placement} />
    }

    return (
      <Tray
        placement={placement}
        direction={widget.direction}
        mirrorTrigger={widget.mirrorTrigger}
      />
    )
  }

  const startWidgets = barLayout.start.map(renderWidget)
  const centerStartWidgets = barLayout.center.start.map(renderWidget)
  const centerAnchor = renderWidget(barLayout.center.anchor)
  const centerEndWidgets = barLayout.center.end.map(renderWidget)
  const endWidgets = barLayout.end.map(renderWidget)

  /* Overall Bar Layout */
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
