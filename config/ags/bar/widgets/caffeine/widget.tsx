import type { NormalizedSwitchMetrics } from "../../primitives/switchTypes.ts"
import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizeRequiredCommand, normalizeStringValue } from "../shared/normalize.ts"
import { normalizeSwitchMetrics } from "./normalize.ts"
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
} satisfies {
  glyph: string
  command: string
  switch: NormalizedSwitchMetrics
}

export default createWidgetSpec({
  kind: "caffeine",
  defaults: caffeineDefaults,
  schema: {
    glyph: normalizeStringValue,
    command: normalizeRequiredCommand,
    switch: normalizeSwitchMetrics,
  },
  render: ({ config, placement }) => (
    <CaffeineWidget
      orientation={placement.orientation}
      glyph={config.glyph}
      command={config.command}
      switchMetrics={config.switch}
    />
  ),
})
