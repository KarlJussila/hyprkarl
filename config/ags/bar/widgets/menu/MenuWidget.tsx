import { Gtk } from "ags/gtk4"
import Button from "../../primitives/Button.tsx"
import type { WidgetRenderArgs } from "../shared/widgetSpec.tsx"
import { useWidgetCommands } from "../shared/useWidgetCommands.ts"
import type { NormalizedSimpleTooltipConfig } from "../shared/normalize.ts"
import { resolveSimpleTooltipText } from "../shared/widgetKit.ts"

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
  const { execPrimary, execSecondary, execTertiary } = useWidgetCommands({ commands })

  return (
    <Button
      class="widget-menu-button widget-glyph-button"
      orientation={placement.orientation}
      tooltipText={resolveSimpleTooltipText(tooltip)}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execTertiary={execTertiary}
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
