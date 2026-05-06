import { execAsync } from "ags/process"
import { Gtk } from "ags/gtk4"
import { type NormalizedMenuWidgetConfig } from "../../configuration"
import { type BarOrientation } from "../../layout/placement"
import Button from "../../primitives/Button"

type Props = {
  orientation: BarOrientation
  config: NormalizedMenuWidgetConfig
}

export default function MenuWidget({ orientation, config }: Props) {
  const isVertical = orientation === "vertical"

  return (
    <Button
      class="menu-button"
      hexpand={isVertical}
      halign={isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      execPrimary={() => execAsync(config.commands.primary).catch(() => {})}
      execSecondary={config.commands.secondary
        ? () => execAsync(config.commands.secondary!).catch(() => {})
        : undefined}
    >
      <box hexpand={isVertical} halign={Gtk.Align.CENTER}>
        <label xalign={0.5} label={config.icon} />
      </box>
    </Button>
  )
}

