import { Gtk } from "ags/gtk4"
import Button from "../../primitives/Button.tsx"
import { useWidgetCommands } from "../shared/useWidgetCommands.ts"
import { mergeConfig, type WidgetClicks, type WidgetProps } from "../shared/types.ts"

export type MenuConfig = {
  icon?: string
  commands?: WidgetClicks
  tooltip?: string
}

type MenuDefaults = {
  icon: string
  commands: WidgetClicks
  tooltip: string
}

export const defaults: MenuDefaults = {
  icon: "",
  commands: { primary: "hk-menu" },
  tooltip: "",
}

export default function Menu({ config, placement }: WidgetProps<MenuConfig>) {
  const cfg = mergeConfig(defaults, config)
  const { icon, commands, tooltip } = cfg
  const isVertical = placement.orientation === "vertical"
  const { execPrimary, execSecondary, execTertiary } = useWidgetCommands({ commands })

  return (
    <Button
      class="widget-menu-button widget-glyph-button"
      orientation={placement.orientation}
      tooltipText={tooltip || undefined}
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
