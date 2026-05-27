import type { NormalizedSliderMetrics } from "../../primitives/sliderTypes.ts"
import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  normalizeBoolean,
  normalizeClickCommandsConfig,
  type NormalizedClickCommandsConfig,
} from "../shared/normalize.ts"
import { normalizeFlyoutConfig } from "../../flyout/normalizeFlyout.ts"
import type { NormalizedFlyoutConfig } from "../../flyout/flyoutTypes.ts"
import { normalizeAudioTooltipConfig, normalizeSliderMetrics } from "./normalize.ts"
import type { NormalizedAudioTooltipConfig } from "./types.ts"
import AudioWidget from "./AudioWidget.tsx"

const audioDefaults = {
  showPercentage: true,
  commands: {
    primary: undefined,
    secondary: "hk-launch-audio",
    tertiary: undefined,
  },
  flyout: {
    enabled: true,
    align: "center",
    gap: 0,
  },
  tooltip: {
    enabled: true,
    active: "{device} {percentage}",
    muted: "Muted {device}",
    unavailable: "Audio unavailable",
  },
  slider: {
    trackLength: 100,
    trackThickness: 6,
    trackRadius: 2,
    fillRadius: 2,
    borderWidth: 1,
    thumbWidth: 10,
    thumbHeight: 10,
    thumbRadius: 5,
    thumbVisible: true,
  },
} satisfies {
  showPercentage: boolean
  commands: NormalizedClickCommandsConfig
  flyout: NormalizedFlyoutConfig
  tooltip: NormalizedAudioTooltipConfig
  slider: NormalizedSliderMetrics
}

export default createWidgetSpec({
  kind: "audio",
  defaults: audioDefaults,
  schema: {
    showPercentage: normalizeBoolean,
    commands: normalizeClickCommandsConfig,
    flyout: normalizeFlyoutConfig,
    tooltip: normalizeAudioTooltipConfig,
    slider: normalizeSliderMetrics,
  },
  render: ({ id, config, placement, monitor }) => (
    <AudioWidget
      id={id}
      placement={placement}
      monitor={monitor}
      showPercentage={config.showPercentage}
      commands={config.commands}
      flyout={config.flyout}
      tooltip={config.tooltip}
      slider={config.slider}
    />
  ),
})
