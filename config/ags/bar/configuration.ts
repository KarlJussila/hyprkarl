/**
 * Shared bar configuration types.
 *
 * Casual users should usually edit:
 * - `config/layout.config.ts`
 * - `config/widgets.config.ts`
 * - `theme.scss`
 */

export type BarEdge = "top" | "bottom" | "left" | "right"
export type TrayDirection = "start" | "end"
export type DropdownAlign = "start" | "center" | "end"

export type BarLayoutConfig = {
  edge: BarEdge
  showCornerCurves?: boolean
  start: Array<string>
  center: {
    start: Array<string>
    anchor?: string
    end: Array<string>
  }
  end: Array<string>
}

export type CommandConfig = {
  primary?: string
  secondary?: string
}

export type NormalizedCommandConfig = {
  primary: string
  secondary?: string
}

export type DropdownConfig = {
  enabled?: boolean
  align?: DropdownAlign
  gap?: number
}

export type NormalizedDropdownConfig = {
  enabled: boolean
  align: DropdownAlign
  gap: number
}

export type TrayRevealConfig = {
  durationMs?: number
}

export type NormalizedTrayRevealConfig = {
  durationMs: number
}

export type ClockDisplayConfig = {
  horizontal?: string
  vertical?: {
    top?: string
    middle?: string
    bottom?: string
  }
}

export type NormalizedClockDisplayConfig = {
  horizontal: string
  vertical: {
    top: string
    middle: string
    bottom: string
  }
}

export type WorkspaceVisibilityConfig = {
  alwaysShow?: Array<number>
  includeFocused?: boolean
  includeOccupied?: boolean
  excludeSpecial?: boolean
}

export type NormalizedWorkspaceVisibilityConfig = {
  alwaysShow: Array<number>
  includeFocused: boolean
  includeOccupied: boolean
  excludeSpecial: boolean
}

export type SwitchMetrics = {
  thumbSize?: number
  trackHeight?: number
  trackLength?: number
  thumbPadding?: number
  glyphOffsetX?: number
  glyphOffsetY?: number
  borderWidth?: number
  fontSize?: number
  fontFamily?: string
}

export type NormalizedSwitchMetrics = {
  thumbSize: number
  trackHeight: number
  trackLength: number
  thumbPadding: number
  glyphOffsetX: number
  glyphOffsetY: number
  borderWidth: number
  fontSize: number
  fontFamily: string
}

export type SliderMetrics = {
  trackLength?: number
  trackThickness?: number
  trackRadius?: number
  fillRadius?: number
  borderWidth?: number
  thumbWidth?: number
  thumbHeight?: number
  thumbRadius?: number
  thumbVisible?: boolean
}

export type NormalizedSliderMetrics = {
  trackLength: number
  trackThickness: number
  trackRadius: number
  fillRadius: number
  borderWidth: number
  thumbWidth: number
  thumbHeight: number
  thumbRadius: number
  thumbVisible: boolean
}

export type BatteryIndicatorMetrics = {
  width?: number
  height?: number
  borderWidth?: number
  terminalWidth?: number
  terminalHeight?: number
  chargingGlyph?: string
  chargingGlyphFontSize?: number
  chargingGlyphFontFamily?: string
}

export type NormalizedBatteryIndicatorMetrics = {
  width: number
  height: number
  borderWidth: number
  terminalWidth: number
  terminalHeight: number
  chargingGlyph: string
  chargingGlyphFontSize: number
  chargingGlyphFontFamily: string
}

export type BatteryTooltipConfig = {
  charging?: string
  discharging?: string
  plugged?: string
  fallback?: string
}

export type NormalizedBatteryTooltipConfig = {
  charging: string
  discharging: string
  plugged: string
  fallback: string
}

export type AudioTooltipConfig = {
  active?: string
  muted?: string
  unavailable?: string
}

export type NormalizedAudioTooltipConfig = {
  active: string
  muted: string
  unavailable: string
}

export type MenuWidgetConfig = {
  kind: "menu"
  icon?: string
  commands?: CommandConfig
}

export type WorkspacesWidgetConfig =
  | {
      kind: "workspaces"
      mode?: "dynamic"
      visibility?: WorkspaceVisibilityConfig
    }
  | {
      kind: "workspaces"
      mode: "fixed"
      ids: Array<number>
    }

export type TrayWidgetConfig = {
  kind: "tray"
  direction?: TrayDirection
  mirrorTrigger?: boolean
  reveal?: TrayRevealConfig
}

export type ClockWidgetConfig = {
  kind: "clock"
  display?: ClockDisplayConfig
  dropdown?: DropdownConfig
}

export type CaffeineWidgetConfig = {
  kind: "caffeine"
  glyph?: string
  command?: string
  advanced?: {
    switch?: SwitchMetrics
  }
}

export type NetworkWidgetConfig = {
  kind: "network"
  command?: string
}

export type BluetoothWidgetConfig = {
  kind: "bluetooth"
  command?: string
}

export type AudioWidgetConfig = {
  kind: "audio"
  showPercentage?: boolean
  command?: string
  dropdown?: DropdownConfig
  tooltip?: AudioTooltipConfig
  advanced?: {
    slider?: SliderMetrics
  }
}

export type BatteryWidgetConfig = {
  kind: "battery"
  showPercentage?: boolean
  lowThreshold?: number
  dropdown?: DropdownConfig
  tooltip?: BatteryTooltipConfig
  advanced?: {
    indicator?: BatteryIndicatorMetrics
  }
}

export type WidgetDefinitionByKind = {
  menu: MenuWidgetConfig
  workspaces: WorkspacesWidgetConfig
  tray: TrayWidgetConfig
  clock: ClockWidgetConfig
  caffeine: CaffeineWidgetConfig
  network: NetworkWidgetConfig
  bluetooth: BluetoothWidgetConfig
  audio: AudioWidgetConfig
  battery: BatteryWidgetConfig
}

export type WidgetKind = keyof WidgetDefinitionByKind
export type BarWidgetDefinition = WidgetDefinitionByKind[WidgetKind]
export type BarWidgetDefinitions = Record<string, BarWidgetDefinition>

export type NormalizedMenuWidgetConfig = {
  kind: "menu"
  icon: string
  commands: NormalizedCommandConfig
}

export type NormalizedWorkspacesWidgetConfig =
  | {
      kind: "workspaces"
      mode: "dynamic"
      visibility: NormalizedWorkspaceVisibilityConfig
    }
  | {
      kind: "workspaces"
      mode: "fixed"
      ids: Array<number>
    }

export type NormalizedTrayWidgetConfig = {
  kind: "tray"
  direction: TrayDirection
  mirrorTrigger: boolean
  reveal: NormalizedTrayRevealConfig
}

export type NormalizedClockWidgetConfig = {
  kind: "clock"
  display: NormalizedClockDisplayConfig
  dropdown: NormalizedDropdownConfig
}

export type NormalizedCaffeineWidgetConfig = {
  kind: "caffeine"
  glyph: string
  command: string
  switch: NormalizedSwitchMetrics
}

export type NormalizedNetworkWidgetConfig = {
  kind: "network"
  command: string
}

export type NormalizedBluetoothWidgetConfig = {
  kind: "bluetooth"
  command: string
}

export type NormalizedAudioWidgetConfig = {
  kind: "audio"
  showPercentage: boolean
  command: string
  dropdown: NormalizedDropdownConfig
  tooltip: NormalizedAudioTooltipConfig
  slider: NormalizedSliderMetrics
}

export type NormalizedBatteryWidgetConfig = {
  kind: "battery"
  showPercentage: boolean
  lowThreshold: number
  dropdown: NormalizedDropdownConfig
  tooltip: NormalizedBatteryTooltipConfig
  indicator: NormalizedBatteryIndicatorMetrics
}

export type NormalizedBarWidgetDefinition =
  | NormalizedMenuWidgetConfig
  | NormalizedWorkspacesWidgetConfig
  | NormalizedTrayWidgetConfig
  | NormalizedClockWidgetConfig
  | NormalizedCaffeineWidgetConfig
  | NormalizedNetworkWidgetConfig
  | NormalizedBluetoothWidgetConfig
  | NormalizedAudioWidgetConfig
  | NormalizedBatteryWidgetConfig

export type NormalizedWidgetConfigByKind = {
  menu: NormalizedMenuWidgetConfig
  workspaces: NormalizedWorkspacesWidgetConfig
  tray: NormalizedTrayWidgetConfig
  clock: NormalizedClockWidgetConfig
  caffeine: NormalizedCaffeineWidgetConfig
  network: NormalizedNetworkWidgetConfig
  bluetooth: NormalizedBluetoothWidgetConfig
  audio: NormalizedAudioWidgetConfig
  battery: NormalizedBatteryWidgetConfig
}

export type ResolvedBarConfiguration = {
  edge: BarEdge
  showCornerCurves: boolean
  layout: {
    start: Array<string>
    center: {
      start: Array<string>
      anchor?: string
      end: Array<string>
    }
    end: Array<string>
  }
  widgets: Record<string, NormalizedBarWidgetDefinition>
}
