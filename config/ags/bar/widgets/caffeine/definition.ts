import type {
  NormalizedCaffeineWidgetConfig,
  WidgetDefinitionByKind,
} from "../../configuration.ts"
import {
  normalizeRequiredCommand,
  normalizeStringValue,
  normalizeSwitchMetrics,
  widgetContext,
} from "../shared/normalize.ts"

const caffeineDefaults: Omit<NormalizedCaffeineWidgetConfig, "kind"> = {
  glyph: "",
  command: "hyprkarl-caffeine",
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
}

export function normalizeCaffeineWidgetConfig(
  id: string,
  definition: WidgetDefinitionByKind["caffeine"],
): NormalizedCaffeineWidgetConfig {
  return {
    kind: "caffeine",
    glyph: normalizeStringValue(
      widgetContext(id, "glyph"),
      definition.glyph,
      caffeineDefaults.glyph,
    ),
    command: normalizeRequiredCommand(
      widgetContext(id, "command"),
      definition.command,
      caffeineDefaults.command,
    ),
    switch: normalizeSwitchMetrics(
      id,
      definition.advanced?.switch,
      caffeineDefaults.switch,
    ),
  }
}

