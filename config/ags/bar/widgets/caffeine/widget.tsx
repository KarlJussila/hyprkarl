import type { NormalizedSwitchMetrics } from "../../primitives/switchTypes.ts"
import {
  createWidgetSpec,
  type WidgetConfig,
} from "../shared/widgetSpec.tsx"
import {
  normalizeRequiredCommand,
  normalizeStringValue,
  widgetContext,
} from "../shared/normalize.ts"
import { normalizeSwitchMetrics } from "./normalize.ts"
import type { SwitchMetrics } from "./types.ts"
import CaffeineWidget from "./CaffeineWidget.tsx"

export type CaffeineWidgetConfig = WidgetConfig<"caffeine", {
  glyph?: string
  command?: string
  switch?: SwitchMetrics
}>

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
  resolve(
    id: string,
    definition: CaffeineWidgetConfig,
    defaults,
  ) {
    return {
      kind: "caffeine",
      glyph: normalizeStringValue(
        widgetContext(id, "glyph"),
        definition.glyph,
        defaults.glyph,
      ),
      command: normalizeRequiredCommand(
        widgetContext(id, "command"),
        definition.command,
        defaults.command,
      ),
      switch: normalizeSwitchMetrics(
        id,
        definition.switch,
        defaults.switch,
      ),
    }
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
