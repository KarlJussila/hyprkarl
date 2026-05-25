import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  normalizeBoolean,
  normalizeSimpleTooltipConfig,
  type NormalizedSimpleTooltipConfig,
} from "../shared/normalize.ts"
import { normalizeRevealConfig, normalizeTrayDirection } from "./normalize.ts"
import type {
  NormalizedTrayRevealConfig,
  TrayDirection,
} from "./types.ts"
import TrayWidget from "./TrayWidget.tsx"

const trayDefaults = {
  direction: "start",
  mirrorTrigger: false,
  reveal: {
    durationMs: 220,
  },
  tooltip: {
    enabled: true,
    text: "",
  },
} satisfies {
  direction: TrayDirection
  mirrorTrigger: boolean
  reveal: NormalizedTrayRevealConfig
  tooltip: NormalizedSimpleTooltipConfig
}

export default createWidgetSpec({
  kind: "tray",
  defaults: trayDefaults,
  schema: {
    direction: normalizeTrayDirection,
    mirrorTrigger: normalizeBoolean,
    reveal: normalizeRevealConfig,
    tooltip: normalizeSimpleTooltipConfig,
  },
  render: ({ config, placement }) => (
    <TrayWidget
      placement={placement}
      direction={config.direction}
      mirrorTrigger={config.mirrorTrigger}
      reveal={config.reveal}
      tooltip={config.tooltip}
    />
  ),
})
