import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizeFlyoutConfig } from "../shared/normalizeFlyout.ts"
import type { NormalizedFlyoutConfig } from "../shared/flyoutTypes.ts"
import { normalizeClockDisplay } from "./normalize.ts"
import type { NormalizedClockDisplayConfig } from "./types.ts"
import ClockWidget from "./ClockWidget.tsx"

const clockDefaults = {
  display: {
    horizontal: "%a %-I:%M %p",
    vertical: {
      top: "%I",
      middle: "%M",
      bottom: "%p",
    },
  },
  flyout: {
    enabled: true,
    align: "center",
    gap: 0,
  },
} satisfies {
  display: NormalizedClockDisplayConfig
  flyout: NormalizedFlyoutConfig
}

export default createWidgetSpec({
  kind: "clock",
  defaults: clockDefaults,
  schema: {
    display: normalizeClockDisplay,
    flyout: normalizeFlyoutConfig,
  },
  render: ({ id, config, placement, monitor }) => (
    <ClockWidget
      id={id}
      placement={placement}
      monitor={monitor}
      display={config.display}
      flyout={config.flyout}
    />
  ),
})
