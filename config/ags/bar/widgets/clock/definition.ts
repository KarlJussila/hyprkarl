import type {
  NormalizedClockWidgetConfig,
  WidgetDefinitionByKind,
} from "../../configuration.ts"
import {
  normalizeClockDisplay,
  normalizeDropdownConfig,
} from "../shared/normalize.ts"

const clockDefaults: Omit<NormalizedClockWidgetConfig, "kind"> = {
  display: {
    horizontal: "%a %-I:%M %p",
    vertical: {
      top: "%I",
      middle: "%M",
      bottom: "%p",
    },
  },
  dropdown: {
    enabled: true,
    align: "center",
    gap: 0,
  },
}

export function normalizeClockWidgetConfig(
  id: string,
  definition: WidgetDefinitionByKind["clock"],
): NormalizedClockWidgetConfig {
  return {
    kind: "clock",
    display: normalizeClockDisplay(id, definition.display, clockDefaults.display),
    dropdown: normalizeDropdownConfig(id, definition.dropdown, clockDefaults.dropdown),
  }
}

