import Button from "../../primitives/Button.tsx"
import { useWidgetCommands } from "../shared/useWidgetCommands.ts"
import type { WidgetRenderArgs } from "../shared/widgetSpec.tsx"
import type { NormalizedClickCommandsConfig, NormalizedSimpleTooltipConfig } from "../shared/normalize.ts"
import { resolveSimpleTooltipText } from "../shared/widgetKit.ts"

type Config = {
  label: string
  active: boolean
  icons: { active: string; inactive: string }
  commands: NormalizedClickCommandsConfig
  tooltip: NormalizedSimpleTooltipConfig
}

export default function TemplateWidget({ config, placement }: WidgetRenderArgs<Config>) {
  const { label, active, icons, commands, tooltip } = config
  const { execPrimary, execSecondary, execTertiary } = useWidgetCommands({ commands })

  return (
    <Button
      class="widget-template-button widget-glyph-button"
      orientation={placement.orientation}
      tooltipText={resolveSimpleTooltipText(tooltip)}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execTertiary={execTertiary}
    >
      <label class="widget-template-label" label={`${active ? icons.active : icons.inactive} ${label}`} />
    </Button>
  )
}
