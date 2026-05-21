import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizeStringValue } from "../shared/normalize.ts"
import { normalizeFlyoutConfig } from "../shared/normalizeFlyout.ts"
import type { NormalizedFlyoutConfig } from "../../overlays/flyout/flyoutTypes.ts"
import ClockWidget from "./ClockWidget.tsx"

const clockDefaults = {
  format: "%a %-I:%M %p",
  formatAlt: "",
  formatVertical: "%I\n%M\n%p",
  formatVerticalAlt: "",
  flyout: {
    enabled: true,
    align: "center",
    gap: 0,
  },
} satisfies {
  format: string
  formatAlt: string
  formatVertical: string
  formatVerticalAlt: string
  flyout: NormalizedFlyoutConfig
}

export default createWidgetSpec({
  kind: "clock",
  defaults: clockDefaults,
  schema: {
    format: normalizeStringValue,
    formatAlt: normalizeStringValue,
    formatVertical: normalizeStringValue,
    formatVerticalAlt: normalizeStringValue,
    flyout: normalizeFlyoutConfig,
  },
  render: ({ id, config, placement, monitor }) => (
    <ClockWidget
      id={id}
      placement={placement}
      monitor={monitor}
      format={config.format}
      formatAlt={config.formatAlt}
      formatVertical={config.formatVertical}
      formatVerticalAlt={config.formatVerticalAlt}
      flyout={config.flyout}
    />
  ),
})
