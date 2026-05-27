import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizeFormatConfig } from "../shared/normalize.ts"
import { flyoutWidgetSchema, flyoutWidgetDefaults } from "../shared/widgetKit.ts"
import ClockWidget from "./ClockWidget.tsx"

export default createWidgetSpec({
  kind: "clock",
  defaults: {
    ...flyoutWidgetDefaults,
    format: {
      primary: "%a %-I:%M %p",
      alt: "",
      vertical: "%I\n%M\n%p",
      verticalAlt: "",
    },
  },
  schema: {
    ...flyoutWidgetSchema,
    format: normalizeFormatConfig,
  },
  render: (args) => (
    <ClockWidget {...args} />
  ),
})
