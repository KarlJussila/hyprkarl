import { Gtk } from "ags/gtk4"
import Button from "../../primitives/Button.tsx"
import type { WidgetRenderArgs } from "../shared/widgetSpec.tsx"
import { useWidgetCommands } from "../shared/useWidgetCommands.ts"
import type { NormalizedSimpleTooltipConfig } from "../shared/normalize.ts"

type Config = {
  icon: string
  commands: {
    primary: string
    secondary: string | undefined
    tertiary: string | undefined
  }
  tooltip: NormalizedSimpleTooltipConfig
}

export default function MenuWidget({ config, placement }: WidgetRenderArgs<Config>) {
  const { icon, commands, tooltip } = config
  const isVertical = placement.orientation === "vertical"
  const { execPrimary, execSecondary, execMiddle } = useWidgetCommands({ commands })

  return (
    <Button
      class="widget-menu-button widget-glyph-button"
      orientation={placement.orientation}
      tooltipText={tooltip.enabled && tooltip.text ? tooltip.text : undefined}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execMiddle={execMiddle}
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
