import audioSpec from "./audio/widget.tsx"
import batterySpec from "./battery/widget.tsx"
import bluetoothSpec from "./bluetooth/widget.tsx"
import caffeineSpec from "./caffeine/widget.tsx"
import clockSpec from "./clock/widget.tsx"
import cpuSpec from "./cpu/widget.tsx"
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
  cpu: cpuSpec,
  network: networkSpec,
  bluetooth: bluetoothSpec,
  audio: audioSpec,
  battery: batterySpec,
}

export type WidgetSpecByKind = typeof widgetCatalog
export type WidgetKind = keyof WidgetSpecByKind

export type WidgetDefinitionByKind = {
  [TKind in WidgetKind]: Parameters<WidgetSpecByKind[TKind]["resolve"]>[1]
}

export type BarWidgetDefinition = WidgetDefinitionByKind[WidgetKind]
export type BarWidgetDefinitions = Record<string, BarWidgetDefinition>

export type ResolvedWidgetConfigByKind = {
  [TKind in WidgetKind]: ReturnType<WidgetSpecByKind[TKind]["resolve"]>
}

export type ResolvedBarWidgetDefinition = ResolvedWidgetConfigByKind[WidgetKind]

export type CatalogWidgetSpec<TKind extends WidgetKind = WidgetKind> =
  WidgetSpecByKind[TKind]

export type { WidgetRenderArgs }
