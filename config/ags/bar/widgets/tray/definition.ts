import type {
  NormalizedTrayWidgetConfig,
  WidgetDefinitionByKind,
} from "../../configuration.ts"
import {
  fail,
  normalizeBoolean,
  normalizeRevealConfig,
  widgetContext,
} from "../shared/normalize.ts"

const trayDefaults: Omit<NormalizedTrayWidgetConfig, "kind"> = {
  direction: "start",
  mirrorTrigger: false,
  reveal: {
    durationMs: 220,
  },
}

function normalizeTrayDirection(id: string, value: unknown, fallback: "start" | "end") {
  const direction = value ?? fallback
  if (direction !== "start" && direction !== "end") {
    fail(widgetContext(id, "direction"), 'must be "start" or "end"')
  }

  return direction
}

export function normalizeTrayWidgetConfig(
  id: string,
  definition: WidgetDefinitionByKind["tray"],
): NormalizedTrayWidgetConfig {
  return {
    kind: "tray",
    direction: normalizeTrayDirection(
      id,
      definition.direction,
      trayDefaults.direction,
    ),
    mirrorTrigger: normalizeBoolean(
      widgetContext(id, "mirrorTrigger"),
      definition.mirrorTrigger,
      trayDefaults.mirrorTrigger,
    ),
    reveal: normalizeRevealConfig(id, definition.reveal, trayDefaults.reveal),
  }
}

