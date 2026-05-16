import type { default as audioSpec } from "./audio/widget.tsx"
import type { default as batterySpec } from "./battery/widget.tsx"
import type { default as bluetoothSpec } from "./bluetooth/widget.tsx"
import type { default as caffeineSpec } from "./caffeine/widget.tsx"
import type { default as clockSpec } from "./clock/widget.tsx"
import type { default as menuSpec } from "./menu/widget.tsx"
import type { default as networkSpec } from "./network/widget.tsx"
import type { default as traySpec } from "./tray/widget.tsx"
import type { default as workspacesSpec } from "./workspaces/widget.tsx"

export type WidgetSpecByKind = {
  menu: typeof menuSpec
  workspaces: typeof workspacesSpec
  tray: typeof traySpec
  clock: typeof clockSpec
  caffeine: typeof caffeineSpec
  network: typeof networkSpec
  bluetooth: typeof bluetoothSpec
  audio: typeof audioSpec
  battery: typeof batterySpec
}

export type WidgetDefinitionByKind = {
  [TKind in keyof WidgetSpecByKind]: Parameters<WidgetSpecByKind[TKind]["resolve"]>[1]
}

export type WidgetKind = keyof WidgetSpecByKind
export type BarWidgetDefinition = WidgetDefinitionByKind[WidgetKind]
export type BarWidgetDefinitions = Record<string, BarWidgetDefinition>

export type ResolvedWidgetConfigByKind = {
  [TKind in keyof WidgetSpecByKind]: ReturnType<WidgetSpecByKind[TKind]["resolve"]>
}

export type ResolvedBarWidgetDefinition =
  ResolvedWidgetConfigByKind[WidgetKind]

export type CatalogWidgetSpec<TKind extends WidgetKind = WidgetKind> =
  WidgetSpecByKind[TKind]
