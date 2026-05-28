import Button from "../../primitives/Button.tsx"
import type { WidgetRenderArgs } from "../shared/widgetSpec.tsx"
import { useWidgetCommands } from "../shared/useWidgetCommands.ts"
import type { NormalizedClickCommandsConfig, NormalizedSimpleTooltipConfig } from "../shared/normalize.ts"
import { resolveSimpleTooltipText } from "../shared/widgetKit.ts"
import { getRecordingController } from "./controller.ts"

type Config = {
  icon: string
  commands: NormalizedClickCommandsConfig
  tooltip: NormalizedSimpleTooltipConfig
}

export default function RecordingWidget({ config, placement }: WidgetRenderArgs<Config>) {
  const { icon, commands, tooltip } = config
  const controller = getRecordingController()
  const { execPrimary, execSecondary, execTertiary } = useWidgetCommands({ commands })

  return (
    <Button
      class="widget-recording-button widget-glyph-button"
      orientation={placement.orientation}
      visible={controller.active}
      tooltipText={resolveSimpleTooltipText(tooltip)}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execTertiary={execTertiary}
    >
      <label class="widget-recording-glyph" xalign={0.5} label={icon} />
    </Button>
  )
}
