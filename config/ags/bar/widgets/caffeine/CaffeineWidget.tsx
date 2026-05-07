import { Gtk } from "ags/gtk4"
import { type NormalizedCaffeineWidgetConfig } from "../../configuration.ts"
import { type BarOrientation } from "../../layout/placement.ts"
import Switch from "../../primitives/Switch"
import { getCaffeineController } from "./controller.ts"

type Props = {
  orientation: BarOrientation
  config: NormalizedCaffeineWidgetConfig
}

export default function CaffeineWidget({ orientation, config }: Props) {
  const isVertical = orientation === "vertical"
  const caffeineController = getCaffeineController()

  return (
    <Switch
      class={`widget-caffeine-switch orientation-${orientation} is-${orientation}`}
      hexpand={isVertical}
      halign={isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      orientation={orientation}
      glyph={config.glyph}
      metrics={config.switch}
      active={caffeineController.active}
      onToggle={(next) => {
        caffeineController.toggle(config.command, next)
      }}
    />
  )
}
