import { createComputed } from "ags"
import { Gtk } from "ags/gtk4"
import type { NormalizedSwitchMetrics } from "../../primitives/switchTypes.ts"
import { type BarOrientation } from "../../layout/placement.ts"
import Switch from "../../primitives/Switch"
import { getCaffeineController } from "./controller.ts"
import type { NormalizedCaffeineTooltip } from "./normalize.ts"

type Props = {
  orientation: BarOrientation
  glyph: string
  command: string
  switchMetrics: NormalizedSwitchMetrics
  tooltip: NormalizedCaffeineTooltip
}

export default function CaffeineWidget({ orientation, glyph, command, switchMetrics, tooltip }: Props) {
  const caffeineController = getCaffeineController()
  const isVertical = orientation === "vertical"

  const tooltipText = createComputed(() =>
    caffeineController.active() ? tooltip.active : tooltip.inactive,
  )

  return (
    <Switch
      class="widget-caffeine-switch widget-glyph-button"
      hexpand={isVertical}
      halign={Gtk.Align.FILL}
      orientation={orientation}
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
