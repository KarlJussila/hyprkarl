import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  composeObject,
  normalizeBoolean,
  normalizeFiniteNumber,
  normalizeNonNegativeNumber,
  normalizePositiveNumber,
  normalizeRequiredCommand,
  normalizeStringValue,
} from "../shared/normalize.ts"
import CaffeineWidget from "./CaffeineWidget.tsx"

const normalizeSwitchMetrics = composeObject({
  thumbSize: normalizePositiveNumber,
  trackHeight: normalizePositiveNumber,
  trackLength: normalizePositiveNumber,
  thumbPadding: normalizeNonNegativeNumber,
  glyphOffsetX: normalizeFiniteNumber,
  glyphOffsetY: normalizeFiniteNumber,
  borderWidth: normalizeNonNegativeNumber,
  fontSize: normalizePositiveNumber,
  fontFamily: normalizeStringValue,
})

const normalizeCaffeineTooltipConfig = composeObject({
  enabled: normalizeBoolean,
  active: normalizeStringValue,
  inactive: normalizeStringValue,
})

export default createWidgetSpec({
  kind: "caffeine",
  defaults: {
    glyph: "",
    command: "hk-caffeine",
    switch: {
      thumbSize: 16,
      trackHeight: 12,
      trackLength: 24,
      thumbPadding: 7,
      glyphOffsetX: 0,
      glyphOffsetY: 0,
      borderWidth: 2,
      fontSize: 8,
      fontFamily: "JetBrains Mono Nerd Font Propo",
    },
    tooltip: {
      enabled: true,
      active: "Caffeine: on",
      inactive: "Caffeine: off",
    },
  },
  schema: {
    glyph: normalizeStringValue,
    command: normalizeRequiredCommand,
    switch: normalizeSwitchMetrics,
    tooltip: normalizeCaffeineTooltipConfig,
  },
  render: (args) => (
    <CaffeineWidget {...args} />
  ),
})
