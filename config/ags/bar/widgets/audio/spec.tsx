import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  composeObject,
  normalizeBoolean,
  normalizeNonNegativeNumber,
  normalizePositiveNumber,
  normalizeStringValue,
} from "../shared/normalize.ts"
import { flyoutWidgetSchema, flyoutWidgetDefaults } from "../shared/widgetKit.ts"
import AudioWidget from "./AudioWidget.tsx"

const normalizeAudioTooltipConfig = composeObject({
  enabled: normalizeBoolean,
  active: normalizeStringValue,
  muted: normalizeStringValue,
  unavailable: normalizeStringValue,
})

const normalizeSliderMetrics = composeObject({
  trackLength: normalizePositiveNumber,
  trackThickness: normalizePositiveNumber,
  trackRadius: normalizeNonNegativeNumber,
  fillRadius: normalizeNonNegativeNumber,
  borderWidth: normalizeNonNegativeNumber,
  thumbWidth: normalizePositiveNumber,
  thumbHeight: normalizePositiveNumber,
  thumbRadius: normalizeNonNegativeNumber,
  thumbVisible: normalizeBoolean,
})

export default createWidgetSpec({
  kind: "audio",
  defaults: {
    ...flyoutWidgetDefaults,
    showPercentage: true,
    commands: {
      primary: undefined,
      secondary: "hk-launch-audio",
      tertiary: undefined,
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
  },
  schema: {
    ...flyoutWidgetSchema,
    showPercentage: normalizeBoolean,
    tooltip: normalizeAudioTooltipConfig,
    slider: normalizeSliderMetrics,
  },
  render: (args) => (
    <AudioWidget {...args} />
  ),
})
