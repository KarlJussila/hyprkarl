import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  normalizeClickCommandsConfig,
  normalizeSimpleTooltipConfig,
  normalizeStringValue,
  type NormalizedClickCommandsConfig,
  type NormalizedSimpleTooltipConfig,
} from "../shared/normalize.ts"
import RecordingWidget from "./RecordingWidget.tsx"

const recordingDefaults = {
  icon: "󰻂",
  commands: {
    primary: "hk-record-screen --stop-recording",
    secondary: undefined,
    tertiary: undefined,
  },
  tooltip: {
    enabled: true,
    text: "Recording — click to stop",
  },
} satisfies {
  icon: string
  commands: NormalizedClickCommandsConfig
  tooltip: NormalizedSimpleTooltipConfig
}

export default createWidgetSpec({
  kind: "recording",
  defaults: recordingDefaults,
  schema: {
    icon: normalizeStringValue,
    commands: normalizeClickCommandsConfig,
    tooltip: normalizeSimpleTooltipConfig,
  },
  render: ({ config, placement }) => (
    <RecordingWidget
      orientation={placement.orientation}
      icon={config.icon}
      commands={config.commands}
      tooltip={config.tooltip}
    />
  ),
})
