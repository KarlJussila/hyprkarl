import type {
  NormalizedAudioWidgetConfig,
  WidgetDefinitionByKind,
} from "../../configuration.ts"
import {
  normalizeAudioTooltipConfig,
  normalizeBoolean,
  normalizeDropdownConfig,
  normalizeRequiredCommand,
  normalizeSliderMetrics,
  widgetContext,
} from "../shared/normalize.ts"

const audioDefaults: Omit<NormalizedAudioWidgetConfig, "kind"> = {
  showPercentage: true,
  command: "hk-launch-audio",
  dropdown: {
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
}

export function normalizeAudioWidgetConfig(
  id: string,
  definition: WidgetDefinitionByKind["audio"],
): NormalizedAudioWidgetConfig {
  return {
    kind: "audio",
    showPercentage: normalizeBoolean(
      widgetContext(id, "showPercentage"),
      definition.showPercentage,
      audioDefaults.showPercentage,
    ),
    command: normalizeRequiredCommand(
      widgetContext(id, "command"),
      definition.command,
      audioDefaults.command,
    ),
    dropdown: normalizeDropdownConfig(id, definition.dropdown, audioDefaults.dropdown),
    tooltip: normalizeAudioTooltipConfig(id, definition.tooltip, audioDefaults.tooltip),
    slider: normalizeSliderMetrics(id, definition.advanced?.slider, audioDefaults.slider),
  }
}
