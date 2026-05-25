import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  normalizeFormatConfig,
  normalizeSimpleTooltipConfig,
  type NormalizedFormatConfig,
  type NormalizedSimpleTooltipConfig,
} from "../shared/normalize.ts"
import { normalizeFlyoutConfig } from "../shared/normalizeFlyout.ts"
import type { NormalizedFlyoutConfig } from "../../overlays/flyout/flyoutTypes.ts"
import ClockWidget from "./ClockWidget.tsx"

const clockDefaults = {
  format: {
    primary: "%a %-I:%M %p",
    alt: "",
    vertical: "%I\n%M\n%p",
    verticalAlt: "",
  },
  flyout: {
    enabled: true,
    align: "center",
    gap: 0,
  },
  tooltip: {
    enabled: true,
    text: "",
  },
} satisfies {
  format: NormalizedFormatConfig
  flyout: NormalizedFlyoutConfig
  tooltip: NormalizedSimpleTooltipConfig
}

export default createWidgetSpec({
  kind: "clock",
  defaults: clockDefaults,
  schema: {
    format: normalizeFormatConfig,
    flyout: normalizeFlyoutConfig,
    tooltip: normalizeSimpleTooltipConfig,
  },
  render: ({ id, config, placement, monitor }) => (
    <ClockWidget
      id={id}
      placement={placement}
      monitor={monitor}
      format={config.format}
      flyout={config.flyout}
      tooltip={config.tooltip}
    />
  ),
})
