import type { NormalizedSliderMetrics } from "../../primitives/sliderTypes.ts"
import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizeBoolean, normalizeRequiredCommand, normalizeStringRecord } from "../shared/normalize.ts"
import { normalizeFlyoutConfig } from "../shared/normalizeFlyout.ts"
import type { NormalizedFlyoutConfig } from "../../overlays/flyout/flyoutTypes.ts"
import { normalizeSliderMetrics } from "./normalize.ts"
import type { NormalizedAudioTooltipConfig } from "./types.ts"
import AudioWidget from "./AudioWidget.tsx"

const audioDefaults = {
  showPercentage: true,
  command: "hk-launch-audio",
  flyout: {
    enabled: true,
    align: "center",
    gap: 0,
  },
  tooltip: {
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
  command: string
  flyout: NormalizedFlyoutConfig
  tooltip: NormalizedAudioTooltipConfig
  slider: NormalizedSliderMetrics
}

export default createWidgetSpec({
  kind: "audio",
  defaults: audioDefaults,
  schema: {
    showPercentage: normalizeBoolean,
    command: normalizeRequiredCommand,
    flyout: normalizeFlyoutConfig,
    tooltip: normalizeStringRecord,
    slider: normalizeSliderMetrics,
  },
  render: ({ id, config, placement, monitor }) => (
    <AudioWidget
      id={id}
      placement={placement}
      monitor={monitor}
      showPercentage={config.showPercentage}
      command={config.command}
      flyout={config.flyout}
      tooltip={config.tooltip}
      slider={config.slider}
    />
  ),
})
