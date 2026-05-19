import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizeBoolean } from "../shared/normalize.ts"
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
} satisfies {
  direction: TrayDirection
  mirrorTrigger: boolean
  reveal: NormalizedTrayRevealConfig
}

export default createWidgetSpec({
  kind: "tray",
  defaults: trayDefaults,
  schema: {
    direction: normalizeTrayDirection,
    mirrorTrigger: normalizeBoolean,
    reveal: normalizeRevealConfig,
  },
  render: ({ config, placement }) => (
    <TrayWidget
      placement={placement}
      direction={config.direction}
      mirrorTrigger={config.mirrorTrigger}
      reveal={config.reveal}
    />
  ),
})
