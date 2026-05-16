import {
  createWidgetSpec,
  type WidgetConfig,
} from "../shared/widgetSpec.tsx"
import { normalizeFlyoutConfig } from "../shared/normalizeFlyout.ts"
import { normalizeClockDisplay } from "./normalize.ts"
import type {
  FlyoutConfig,
  NormalizedFlyoutConfig,
} from "../shared/flyoutTypes.ts"
import type {
  ClockDisplayConfig,
  NormalizedClockDisplayConfig,
} from "./types.ts"
import ClockWidget from "./ClockWidget.tsx"

export type ClockWidgetConfig = WidgetConfig<"clock", {
  display?: ClockDisplayConfig
  flyout?: FlyoutConfig
}>

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
  resolve(
    id: string,
    definition: ClockWidgetConfig,
    defaults,
  ) {
    return {
      kind: "clock",
      display: normalizeClockDisplay(id, definition.display, defaults.display),
      flyout: normalizeFlyoutConfig(id, definition.flyout, defaults.flyout),
    }
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
