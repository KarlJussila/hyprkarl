import { Gtk } from "ags/gtk4"
import { type BarOrientation } from "../../layout/placement"
import Button from "../../primitives/Button"
import { resolveCommand } from "../shared/resolveCommand.ts"
import type { NormalizedSimpleTooltipConfig } from "../shared/normalize.ts"
import type { NormalizedCommandConfig } from "./types.ts"

type Props = {
  orientation: BarOrientation
  icon: string
  commands: NormalizedCommandConfig
  tooltip: NormalizedSimpleTooltipConfig
}

export default function MenuWidget({ orientation, icon, commands, tooltip }: Props) {
  const isVertical = orientation === "vertical"

  return (
    <Button
      class="widget-menu-button widget-glyph-button"
      orientation={orientation}
      tooltipText={tooltip.enabled && tooltip.text ? tooltip.text : undefined}
      execPrimary={resolveCommand(commands.primary, undefined)}
      execSecondary={resolveCommand(commands.secondary, undefined)}
      execMiddle={resolveCommand(commands.tertiary, undefined)}
    >
      <box
        class="widget-menu-content"
        hexpand={isVertical}
        halign={Gtk.Align.CENTER}
      >
        <label class="widget-menu-glyph" xalign={0.5} label={icon} />
      </box>
    </Button>
  )
}
