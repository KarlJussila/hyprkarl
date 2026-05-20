import { Gtk } from "ags/gtk4"
import type { NormalizedSwitchMetrics } from "../../primitives/switchTypes.ts"
import { type BarOrientation } from "../../layout/placement.ts"
import Switch from "../../primitives/Switch"
import { getCaffeineController } from "./controller.ts"

type Props = {
  orientation: BarOrientation
  glyph: string
  command: string
  switchMetrics: NormalizedSwitchMetrics
}

export default function CaffeineWidget({ orientation, glyph, command, switchMetrics }: Props) {
  const caffeineController = getCaffeineController()
  const isVertical = orientation === "vertical"

  return (
    <Switch
      class={`widget-caffeine-switch orientation-${orientation} is-${orientation}`}
      hexpand={isVertical}
      halign={Gtk.Align.FILL}
      orientation={orientation}
      glyph={glyph}
      metrics={switchMetrics}
      active={caffeineController.active}
      onToggle={(next) => {
        caffeineController.toggle(command, next)
      }}
    />
  )
}
