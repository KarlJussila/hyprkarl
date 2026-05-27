import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  normalizeBoolean,
  normalizeRevealConfig,
  normalizeSimpleTooltipConfig,
  type NormalizedRevealConfig,
  type NormalizedSimpleTooltipConfig,
} from "../shared/normalize.ts"
import { normalizeTrayDirection } from "./normalize.ts"
import type { TrayDirection } from "./types.ts"
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
  reveal: NormalizedRevealConfig
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
