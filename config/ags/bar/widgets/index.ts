/**
 * Central widget registry.
 *
 * Each entry maps a `kind` string to a Component and its `defaults` object.
 * The `WidgetDefinition` union below is the type that `widgets.config.ts`
 * satisfies — adding a new widget here flows through into the user-facing
 * config types automatically.
 */
import Clock,      { defaults as clockDefaults,      type ClockConfig }      from "./clock"
import Cpu,        { defaults as cpuDefaults,        type CpuConfig }        from "./cpu"
import Gpu,        { defaults as gpuDefaults,        type GpuConfig }        from "./gpu"
import Menu,       { defaults as menuDefaults,       type MenuConfig }       from "./menu"
import Ram,        { defaults as ramDefaults,        type RamConfig }        from "./ram"
import Recording,  { defaults as recordingDefaults,  type RecordingConfig }  from "./recording"
import Template,   { defaults as templateDefaults,   type TemplateConfig }   from "./_template"
import Audio,      { defaults as audioDefaults,      type AudioConfig }      from "./audio"
import Battery,    { defaults as batteryDefaults,    type BatteryConfig }    from "./battery"
import Bluetooth,  { defaults as bluetoothDefaults,  type BluetoothConfig }  from "./bluetooth"
import Network,    { defaults as networkDefaults,    type NetworkConfig }    from "./network"
import Toggle,     { defaults as toggleDefaults,     type ToggleConfig }     from "./toggle"
import Tray,       { defaults as trayDefaults,       type TrayConfig }       from "./tray"
import Workspaces, { defaults as workspacesDefaults, type WorkspacesConfig } from "./workspaces"

import type { BarLayoutConfig } from "../types.ts"

export const widgets = {
  clock:      { Component: Clock,      defaults: clockDefaults },
  cpu:        { Component: Cpu,        defaults: cpuDefaults },
  gpu:        { Component: Gpu,        defaults: gpuDefaults },
  menu:       { Component: Menu,       defaults: menuDefaults },
  ram:        { Component: Ram,        defaults: ramDefaults },
  recording:  { Component: Recording,  defaults: recordingDefaults },
  _template:  { Component: Template,   defaults: templateDefaults },
  audio:      { Component: Audio,      defaults: audioDefaults },
  battery:    { Component: Battery,    defaults: batteryDefaults },
  bluetooth:  { Component: Bluetooth,  defaults: bluetoothDefaults },
  network:    { Component: Network,    defaults: networkDefaults },
  toggle:     { Component: Toggle,     defaults: toggleDefaults },
  tray:       { Component: Tray,       defaults: trayDefaults },
  workspaces: { Component: Workspaces, defaults: workspacesDefaults },
} as const

export type WidgetKind = keyof typeof widgets

type ConfigByKind = {
  clock: ClockConfig
  menu: MenuConfig
  cpu: CpuConfig
  gpu: GpuConfig
  ram: RamConfig
  recording: RecordingConfig
  _template: TemplateConfig
  audio: AudioConfig
  battery: BatteryConfig
  bluetooth: BluetoothConfig
  network: NetworkConfig
  toggle: ToggleConfig
  tray: TrayConfig
  workspaces: WorkspacesConfig
}

export type WidgetDefinition = {
  [K in WidgetKind]: { kind: K } & ConfigByKind[K]
}[WidgetKind]

export type WidgetDefinitions = Record<string, WidgetDefinition>

/**
 * The only runtime validation in the bar config pipeline.
 *
 * Throws a readable `Error` if a layout entry names a widget that wasn't
 * defined in `widgets.config.ts`, or if a widget's `kind` doesn't match any
 * registered widget. Everything else is enforced by the TypeScript compiler.
 */
export function assertWidgetsExist(
  layout: BarLayoutConfig,
  definitions: WidgetDefinitions,
): void {
  const allIds = [
    ...layout.start,
    ...layout.center.start,
    ...layout.center.center,
    ...layout.center.end,
    ...layout.end,
  ]

  for (const id of allIds) {
    const def = definitions[id]
    if (!def) {
      throw new Error(`layout references unknown widget "${id}"`)
    }
    if (!(def.kind in widgets)) {
      throw new Error(`widget "${id}" has unknown kind "${def.kind}"`)
    }
  }

  if (
    layout.center.center.length === 0 &&
    (layout.center.start.length > 0 || layout.center.end.length > 0)
  ) {
    throw new Error(
      'center.center must have at least one widget when center.start or center.end are used',
    )
  }
}
