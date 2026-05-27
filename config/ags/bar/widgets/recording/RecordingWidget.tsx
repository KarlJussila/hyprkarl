import { type BarOrientation } from "../../layout/placement.ts"
import Button from "../../primitives/Button.tsx"
import { resolveCommand } from "../shared/resolveCommand.ts"
import type { NormalizedClickCommandsConfig, NormalizedSimpleTooltipConfig } from "../shared/normalize.ts"
import { getRecordingController } from "./controller.ts"

type Props = {
  orientation: BarOrientation
  icon: string
  commands: NormalizedClickCommandsConfig
  tooltip: NormalizedSimpleTooltipConfig
}

export default function RecordingWidget({ orientation, icon, commands, tooltip }: Props) {
  const controller = getRecordingController()

  const execPrimary = resolveCommand(commands.primary, undefined)
  const execSecondary = resolveCommand(commands.secondary, undefined)
  const execMiddle = resolveCommand(commands.tertiary, undefined)

  return (
    <Button
      class="widget-recording-button widget-glyph-button"
      orientation={orientation}
      visible={controller.active}
      tooltipText={tooltip.enabled && tooltip.text ? tooltip.text : undefined}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execMiddle={execMiddle}
    >
      <label class="widget-recording-glyph" xalign={0.5} label={icon} />
    </Button>
  )
}
