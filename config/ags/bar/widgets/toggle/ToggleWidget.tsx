import { createComputed } from "ags"
import { Gtk } from "ags/gtk4"
import type { NormalizedSwitchMetrics } from "../../primitives/switchTypes.ts"
import Switch from "../../primitives/Switch.tsx"
import type { WidgetRenderArgs } from "../shared/widgetSpec.tsx"
import { getToggleController } from "./controller.ts"

type Config = {
  commands: { on: string; off: string; sync: string }
  endpoint: string
  switch: NormalizedSwitchMetrics
  tooltip: { active: string; inactive: string }
}

export default function ToggleWidget({ config, placement }: WidgetRenderArgs<Config>) {
  const { commands, endpoint, switch: switchMetrics, tooltip } = config
  const controller = getToggleController(commands, endpoint)
  const isVertical = placement.orientation === "vertical"

  const tooltipText = tooltip.active || tooltip.inactive
    ? createComputed(() => controller.active() ? tooltip.active : tooltip.inactive)
    : undefined

  return (
    <Switch
      class="widget-toggle-switch widget-glyph-button"
      hexpand={isVertical}
      halign={Gtk.Align.FILL}
      orientation={placement.orientation}
      metrics={switchMetrics}
      active={controller.active}
      tooltipText={tooltipText}
      onToggle={(next) => {
        controller.toggle(commands, next)
      }}
    />
  )
}
