import { createPollingMonitorWidgetSpec } from "../shared/createPollingMonitorWidgetSpec.tsx"
import CpuWidget from "./CpuWidget.tsx"

export default createPollingMonitorWidgetSpec({
  kind: "cpu",
  defaults: {
    icon: "󰍛",
    format: { primary: "", alt: "", vertical: "", verticalAlt: "" },
    decimals: { primary: 0, alt: 0, vertical: 0, verticalAlt: 0 },
    tooltip: { enabled: true, text: "CPU: {usage}%\n{cores}" },
    interval: 5000,
    reveal: { durationMs: 200 },
    commands: { primary: undefined, secondary: undefined, tertiary: undefined },
  },
  Component: CpuWidget,
})
