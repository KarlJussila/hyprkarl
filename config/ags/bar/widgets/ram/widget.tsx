import { createPollingMonitorWidgetSpec } from "../shared/createPollingMonitorWidgetSpec.tsx"
import RamWidget from "./RamWidget.tsx"

export default createPollingMonitorWidgetSpec({
  kind: "ram",
  defaults: {
    icon: "",
    format: {
      primary: "{ram}%",
      alt: "{ram_used}/{ram_total} | {swap_used}/{swap_total}",
      vertical: "{ram}%",
      verticalAlt: "{ram_used}\n{swap_used}",
    },
    decimals: { primary: 0, alt: 0, vertical: 0, verticalAlt: 0 },
    tooltip: { enabled: true, text: "RAM: {ram_used}/{ram_total}\nSwap: {swap_used}/{swap_total}" },
    interval: 5000,
    reveal: { durationMs: 200 },
  },
  Component: RamWidget,
})
