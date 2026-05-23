import type { NormalizedSwitchMetrics } from "../../primitives/switchTypes.ts"
import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizeRequiredCommand, normalizeStringValue } from "../shared/normalize.ts"
import { normalizeCaffeineTooltip, normalizeSwitchMetrics } from "./normalize.ts"
import type { NormalizedCaffeineTooltip } from "./normalize.ts"
import CaffeineWidget from "./CaffeineWidget.tsx"

const caffeineDefaults = {
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
    active: "Caffeine: on",
    inactive: "Caffeine: off",
  },
} satisfies {
  glyph: string
  command: string
  switch: NormalizedSwitchMetrics
  tooltip: NormalizedCaffeineTooltip
}

export default createWidgetSpec({
  kind: "caffeine",
  defaults: caffeineDefaults,
  schema: {
    glyph: normalizeStringValue,
    command: normalizeRequiredCommand,
    switch: normalizeSwitchMetrics,
    tooltip: normalizeCaffeineTooltip,
  },
  render: ({ config, placement }) => (
    <CaffeineWidget
      orientation={placement.orientation}
      glyph={config.glyph}
      command={config.command}
      switchMetrics={config.switch}
      tooltip={config.tooltip}
    />
  ),
})
