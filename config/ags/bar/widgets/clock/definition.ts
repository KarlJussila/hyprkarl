import type {
  NormalizedClockWidgetConfig,
  WidgetDefinitionByKind,
} from "../../configuration.ts"
import {
  normalizeClockDisplay,
  normalizeFlyoutConfig,
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
  flyout: {
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
    flyout: normalizeFlyoutConfig(id, definition.flyout, clockDefaults.flyout),
  }
}
