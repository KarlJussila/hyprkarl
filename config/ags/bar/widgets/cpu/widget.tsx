import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizePositiveNumber, normalizeStringValue } from "../shared/normalize.ts"
import CpuWidget from "./CpuWidget.tsx"

const cpuDefaults = {
  icon: "󰍛",
  format: "",
  formatAlt: "",
  formatVertical: "",
  formatVerticalAlt: "",
  tooltip: "CPU: {usage}%\n{cores}",
  interval: 2000,
}

export default createWidgetSpec({
  kind: "cpu",
  defaults: cpuDefaults,
  schema: {
    icon: normalizeStringValue,
    format: normalizeStringValue,
    formatAlt: normalizeStringValue,
    formatVertical: normalizeStringValue,
    formatVerticalAlt: normalizeStringValue,
    tooltip: normalizeStringValue,
    interval: normalizePositiveNumber,
  },
  render: ({ config, placement }) => (
    <CpuWidget
      orientation={placement.orientation}
      icon={config.icon}
      format={config.format}
      formatAlt={config.formatAlt}
      formatVertical={config.formatVertical}
      formatVerticalAlt={config.formatVerticalAlt}
      tooltip={config.tooltip}
      interval={config.interval}
    />
  ),
})
