import type {
  CatalogWidgetSpec,
  ResolvedBarWidgetDefinition,
  WidgetKind,
} from "./widgetTypes.ts"
import audioSpec from "./audio/widget.tsx"
import batterySpec from "./battery/widget.tsx"
import bluetoothSpec from "./bluetooth/widget.tsx"
import caffeineSpec from "./caffeine/widget.tsx"
import clockSpec from "./clock/widget.tsx"
import menuSpec from "./menu/widget.tsx"
import networkSpec from "./network/widget.tsx"
import traySpec from "./tray/widget.tsx"
import workspacesSpec from "./workspaces/widget.tsx"
import type { WidgetRenderArgs } from "./shared/widgetSpec.tsx"

export const widgetCatalog = {
  menu: menuSpec,
  workspaces: workspacesSpec,
  tray: traySpec,
  clock: clockSpec,
  caffeine: caffeineSpec,
  network: networkSpec,
  bluetooth: bluetoothSpec,
  audio: audioSpec,
  battery: batterySpec,
} satisfies { [TKind in WidgetKind]: CatalogWidgetSpec<TKind> }

export type { WidgetRenderArgs }
export type { ResolvedBarWidgetDefinition }
