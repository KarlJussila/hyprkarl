import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizeFormatConfig } from "../shared/normalize.ts"
import type { NormalizedFormatConfig } from "../shared/normalize.ts"
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
} satisfies {
  format: NormalizedFormatConfig
  flyout: NormalizedFlyoutConfig
}

export default createWidgetSpec({
  kind: "clock",
  defaults: clockDefaults,
  schema: {
    format: normalizeFormatConfig,
    flyout: normalizeFlyoutConfig,
  },
  render: ({ id, config, placement, monitor }) => (
    <ClockWidget
      id={id}
      placement={placement}
      monitor={monitor}
      format={config.format}
      flyout={config.flyout}
    />
  ),
})
