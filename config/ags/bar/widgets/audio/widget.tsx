import type { NormalizedSliderMetrics } from "../../primitives/sliderTypes.ts"
import {
  createWidgetSpec,
  type WidgetConfig,
} from "../shared/widgetSpec.tsx"
import {
  normalizeBoolean,
  normalizeRequiredCommand,
  widgetContext,
} from "../shared/normalize.ts"
import { normalizeFlyoutConfig } from "../shared/normalizeFlyout.ts"
import {
  normalizeAudioTooltipConfig,
  normalizeSliderMetrics,
} from "./normalize.ts"
import type {
  FlyoutConfig,
  NormalizedFlyoutConfig,
} from "../shared/flyoutTypes.ts"
import type {
  AudioTooltipConfig,
  NormalizedAudioTooltipConfig,
  SliderMetrics,
} from "./types.ts"
import AudioWidget from "./AudioWidget.tsx"

export type AudioWidgetConfig = WidgetConfig<"audio", {
  showPercentage?: boolean
  command?: string
  flyout?: FlyoutConfig
  tooltip?: AudioTooltipConfig
  slider?: SliderMetrics
}>

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
  resolve(
    id: string,
    definition: AudioWidgetConfig,
    defaults,
  ) {
    return {
      kind: "audio",
      showPercentage: normalizeBoolean(
        widgetContext(id, "showPercentage"),
        definition.showPercentage,
        defaults.showPercentage,
      ),
      command: normalizeRequiredCommand(
        widgetContext(id, "command"),
        definition.command,
        defaults.command,
      ),
      flyout: normalizeFlyoutConfig(id, definition.flyout, defaults.flyout),
      tooltip: normalizeAudioTooltipConfig(id, definition.tooltip, defaults.tooltip),
      slider: normalizeSliderMetrics(id, definition.slider, defaults.slider),
    }
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
