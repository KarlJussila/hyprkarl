import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizePositiveNumber, normalizeStringValue } from "../shared/normalize.ts"
import CpuWidget from "./CpuWidget.tsx"

const cpuDefaults = {
  icon: "󰍛",
  format: "",
  tooltip: "CPU: {usage}%\n{cores}",
  interval: 2000,
}

export default createWidgetSpec({
  kind: "cpu",
  defaults: cpuDefaults,
  schema: {
    icon: normalizeStringValue,
    format: normalizeStringValue,
    tooltip: normalizeStringValue,
    interval: normalizePositiveNumber,
  },
  render: ({ config, placement }) => (
    <CpuWidget
      orientation={placement.orientation}
      icon={config.icon}
      format={config.format}
      tooltip={config.tooltip}
      interval={config.interval}
    />
  ),
})
