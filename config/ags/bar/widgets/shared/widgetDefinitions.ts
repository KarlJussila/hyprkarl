import type {
  NormalizedWidgetConfigByKind,
  WidgetDefinitionByKind,
  WidgetKind,
} from "../../configuration.ts"
import { normalizeBatteryWidgetConfig } from "../battery/definition.ts"
import { normalizeCaffeineWidgetConfig } from "../caffeine/definition.ts"
import { normalizeClockWidgetConfig } from "../clock/definition.ts"
import { normalizeMenuWidgetConfig } from "../menu/definition.ts"
import { normalizeTrayWidgetConfig } from "../tray/definition.ts"
import { normalizeWorkspacesWidgetConfig } from "../workspaces/definition.ts"

export type WidgetDefinitionEntry<TKind extends WidgetKind> = {
  kind: TKind
  normalize: (
    id: string,
    definition: WidgetDefinitionByKind[TKind],
  ) => NormalizedWidgetConfigByKind[TKind]
}

export const widgetDefinitionsByKind = {
  menu: {
    kind: "menu",
    normalize: normalizeMenuWidgetConfig,
  },
  workspaces: {
    kind: "workspaces",
    normalize: normalizeWorkspacesWidgetConfig,
  },
  tray: {
    kind: "tray",
    normalize: normalizeTrayWidgetConfig,
  },
  clock: {
    kind: "clock",
    normalize: normalizeClockWidgetConfig,
  },
  caffeine: {
    kind: "caffeine",
    normalize: normalizeCaffeineWidgetConfig,
  },
  battery: {
    kind: "battery",
    normalize: normalizeBatteryWidgetConfig,
  },
} satisfies { [TKind in WidgetKind]: WidgetDefinitionEntry<TKind> }

