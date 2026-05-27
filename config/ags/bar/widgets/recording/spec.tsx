import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizeStringValue } from "../shared/normalize.ts"
import { commonWidgetSchema, commonWidgetDefaults } from "../shared/widgetKit.ts"
import RecordingWidget from "./RecordingWidget.tsx"

export default createWidgetSpec({
  kind: "recording",
  defaults: {
    ...commonWidgetDefaults,
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
  },
  schema: {
    ...commonWidgetSchema,
    icon: normalizeStringValue,
  },
  render: (args) => (
    <RecordingWidget {...args} />
  ),
})
