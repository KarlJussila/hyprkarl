import { createComputed } from "ags"
import { Gtk } from "ags/gtk4"
import type { NormalizedSwitchMetrics } from "../../primitives/switchTypes.ts"
import Switch from "../../primitives/Switch.tsx"
import type { WidgetRenderArgs } from "../shared/widgetSpec.tsx"
import { getCaffeineController } from "./controller.ts"

type Config = {
  glyph: string
  command: string
  switch: NormalizedSwitchMetrics
  tooltip: { enabled: boolean; active: string; inactive: string }
}

export default function CaffeineWidget({ config, placement }: WidgetRenderArgs<Config>) {
  const { glyph, command, switch: switchMetrics, tooltip } = config
  const caffeineController = getCaffeineController()
  const isVertical = placement.orientation === "vertical"

  const tooltipText = tooltip.enabled
    ? createComputed(() => caffeineController.active() ? tooltip.active : tooltip.inactive)
    : undefined

  return (
    <Switch
      class="widget-caffeine-switch widget-glyph-button"
      hexpand={isVertical}
      halign={Gtk.Align.FILL}
      orientation={placement.orientation}
      glyph={glyph}
      metrics={switchMetrics}
      active={caffeineController.active}
      tooltipText={tooltipText}
      onToggle={(next) => {
        caffeineController.toggle(command, next)
      }}
    />
  )
}
