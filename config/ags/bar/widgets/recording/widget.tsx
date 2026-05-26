import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  normalizeRequiredCommand,
  normalizeSimpleTooltipConfig,
  normalizeStringValue,
  type NormalizedSimpleTooltipConfig,
} from "../shared/normalize.ts"
import RecordingWidget from "./RecordingWidget.tsx"

const recordingDefaults = {
  icon: "󰻂",
  command: "hk-record-screen --stop-recording",
  tooltip: {
    enabled: true,
    text: "Recording — click to stop",
  },
} satisfies {
  icon: string
  command: string
  tooltip: NormalizedSimpleTooltipConfig
}

export default createWidgetSpec({
  kind: "recording",
  defaults: recordingDefaults,
  schema: {
    icon: normalizeStringValue,
    command: normalizeRequiredCommand,
    tooltip: normalizeSimpleTooltipConfig,
  },
  render: ({ config, placement }) => (
    <RecordingWidget
      orientation={placement.orientation}
      icon={config.icon}
      command={config.command}
      tooltip={config.tooltip}
    />
  ),
})
