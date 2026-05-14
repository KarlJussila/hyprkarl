import { Gdk } from "ags/gtk4"
import type {
  NormalizedBarWidgetDefinition,
  NormalizedWidgetConfigByKind,
  WidgetKind,
} from "../../configuration.ts"
import { type BarPlacement } from "../../layout/placement.ts"
import batteryManifest from "../battery/manifest.tsx"
import bluetoothManifest from "../bluetooth/manifest.tsx"
import caffeineManifest from "../caffeine/manifest.tsx"
import clockManifest from "../clock/manifest.tsx"
import menuManifest from "../menu/manifest.tsx"
import networkManifest from "../network/manifest.tsx"
import trayManifest from "../tray/manifest.tsx"
import workspacesManifest from "../workspaces/manifest.tsx"

export type WidgetRenderArgs<TConfig extends NormalizedBarWidgetDefinition> = {
  id: string
  config: TConfig
  placement: BarPlacement
  monitor: Gdk.Monitor
}

export type WidgetManifest<TKind extends WidgetKind> = {
  kind: TKind
  render: (args: WidgetRenderArgs<NormalizedWidgetConfigByKind[TKind]>) => JSX.Element
}

export const widgetManifests = {
  menu: menuManifest,
  workspaces: workspacesManifest,
  tray: trayManifest,
  clock: clockManifest,
  caffeine: caffeineManifest,
  network: networkManifest,
  bluetooth: bluetoothManifest,
  battery: batteryManifest,
} satisfies { [TKind in WidgetKind]: WidgetManifest<TKind> }
