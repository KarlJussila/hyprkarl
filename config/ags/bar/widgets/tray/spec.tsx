import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  fail,
  normalizeBoolean,
  normalizeRevealConfig,
  normalizeSimpleTooltipConfig,
  type FieldNormalizer,
} from "../shared/normalize.ts"
import TrayWidget from "./TrayWidget.tsx"

export type TrayDirection = "start" | "end"

const normalizeTrayDirection: FieldNormalizer<TrayDirection, TrayDirection> = (ctx, value, fallback) => {
  const direction = value ?? fallback
  if (direction !== "start" && direction !== "end") {
    fail(ctx, 'must be "start" or "end"')
  }
  return direction
}

export default createWidgetSpec({
  kind: "tray",
  defaults: {
    direction: "start",
    mirrorTrigger: false,
    reveal: { durationMs: 220 },
    tooltip: { enabled: true, text: "" },
  },
  schema: {
    direction: normalizeTrayDirection,
    mirrorTrigger: normalizeBoolean,
    reveal: normalizeRevealConfig,
    tooltip: normalizeSimpleTooltipConfig,
  },
  render: (args) => (
    <TrayWidget {...args} />
  ),
})
