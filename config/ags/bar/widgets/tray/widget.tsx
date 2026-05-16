import {
  createWidgetSpec,
  type WidgetConfig,
} from "../shared/widgetSpec.tsx"
import {
  normalizeBoolean,
  widgetContext,
} from "../shared/normalize.ts"
import {
  normalizeRevealConfig,
  normalizeTrayDirection,
} from "./normalize.ts"
import type {
  NormalizedTrayRevealConfig,
  TrayDirection,
  TrayRevealConfig,
} from "./types.ts"
import TrayWidget from "./TrayWidget.tsx"

export type TrayWidgetConfig = WidgetConfig<"tray", {
  direction?: TrayDirection
  mirrorTrigger?: boolean
  reveal?: TrayRevealConfig
}>

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
  resolve(
    id: string,
    definition: TrayWidgetConfig,
    defaults,
  ) {
    return {
      kind: "tray",
      direction: normalizeTrayDirection(
        id,
        definition.direction,
        defaults.direction,
      ),
      mirrorTrigger: normalizeBoolean(
        widgetContext(id, "mirrorTrigger"),
        definition.mirrorTrigger,
        defaults.mirrorTrigger,
      ),
      reveal: normalizeRevealConfig(id, definition.reveal, defaults.reveal),
    }
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
