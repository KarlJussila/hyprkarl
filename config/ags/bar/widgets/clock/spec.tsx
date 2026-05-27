import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  normalizeClickCommandsConfig,
  normalizeFormatConfig,
  normalizeSimpleTooltipConfig,
  type NormalizedClickCommandsConfig,
  type NormalizedFormatConfig,
  type NormalizedSimpleTooltipConfig,
} from "../shared/normalize.ts"
import { normalizeFlyoutConfig } from "../../flyout/normalizeFlyout.ts"
import type { NormalizedFlyoutConfig } from "../../flyout/flyoutTypes.ts"
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
  commands: {
    primary: undefined,
    secondary: undefined,
    tertiary: undefined,
  },
} satisfies {
  format: NormalizedFormatConfig
  flyout: NormalizedFlyoutConfig
  tooltip: NormalizedSimpleTooltipConfig
  commands: NormalizedClickCommandsConfig
}

export default createWidgetSpec({
  kind: "clock",
  defaults: clockDefaults,
  schema: {
    format: normalizeFormatConfig,
    flyout: normalizeFlyoutConfig,
    tooltip: normalizeSimpleTooltipConfig,
    commands: normalizeClickCommandsConfig,
  },
  render: ({ id, config, placement, monitor }) => (
    <ClockWidget
      id={id}
      placement={placement}
      monitor={monitor}
      format={config.format}
      flyout={config.flyout}
      tooltip={config.tooltip}
      commands={config.commands}
    />
  ),
})
