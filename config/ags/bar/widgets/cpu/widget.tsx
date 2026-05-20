import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizeBoolean, normalizePositiveNumber, normalizeStringValue, normalizeUnitInterval } from "../shared/normalize.ts"
import CpuWidget from "./CpuWidget.tsx"

const cpuDefaults = {
  icon: "󰘚",
  showPercentage: false,
  interval: 2000,
  warningThreshold: 0.75,
}

export default createWidgetSpec({
  kind: "cpu",
  defaults: cpuDefaults,
  schema: {
    icon: normalizeStringValue,
    showPercentage: normalizeBoolean,
    interval: normalizePositiveNumber,
    warningThreshold: normalizeUnitInterval,
  },
  render: ({ config, placement }) => (
    <CpuWidget
      orientation={placement.orientation}
      icon={config.icon}
      showPercentage={config.showPercentage}
      warningThreshold={config.warningThreshold}
      interval={config.interval}
    />
  ),
})
