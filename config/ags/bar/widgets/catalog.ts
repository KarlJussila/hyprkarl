import audioSpec from "./audio/spec.tsx"
import recordingSpec from "./recording/spec.tsx"
import batterySpec from "./battery/spec.tsx"
import bluetoothSpec from "./bluetooth/spec.tsx"
import caffeineSpec from "./caffeine/spec.tsx"
import clockSpec from "./clock/spec.tsx"
import cpuSpec from "./cpu/spec.tsx"
import ramSpec from "./ram/spec.tsx"
import menuSpec from "./menu/spec.tsx"
import networkSpec from "./network/spec.tsx"
import traySpec from "./tray/spec.tsx"
import workspacesSpec from "./workspaces/spec.tsx"
import type { WidgetRenderArgs } from "./shared/widgetSpec.tsx"

export const widgetCatalog = {
  menu: menuSpec,
  workspaces: workspacesSpec,
  tray: traySpec,
  clock: clockSpec,
  caffeine: caffeineSpec,
  cpu: cpuSpec,
  ram: ramSpec,
  network: networkSpec,
  bluetooth: bluetoothSpec,
  audio: audioSpec,
  battery: batterySpec,
  recording: recordingSpec,
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
