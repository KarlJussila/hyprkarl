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

export type BatteryIndicatorMetrics = {
  width?: number
  height?: number
  borderWidth?: number
  terminalWidth?: number
  terminalHeightRatio?: number
  chargingGlyph?: string
  chargingGlyphFontSize?: number
  chargingGlyphFontFamily?: string
}

export type NormalizedBatteryIndicatorMetrics = {
  width: number
  height: number
  borderWidth: number
  terminalWidth: number
  terminalHeightRatio: number
  chargingGlyph: string
  chargingGlyphFontSize: number
  chargingGlyphFontFamily: string
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

export type BatteryWidgetConfig = {
  kind: "battery"
  showPercentage?: boolean
  lowThreshold?: number
  dropdown?: DropdownConfig
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

export type NormalizedBatteryWidgetConfig = {
  kind: "battery"
  showPercentage: boolean
  lowThreshold: number
  dropdown: NormalizedDropdownConfig
  indicator: NormalizedBatteryIndicatorMetrics
}

export type NormalizedBarWidgetDefinition =
  | NormalizedMenuWidgetConfig
  | NormalizedWorkspacesWidgetConfig
  | NormalizedTrayWidgetConfig
  | NormalizedClockWidgetConfig
  | NormalizedCaffeineWidgetConfig
  | NormalizedBatteryWidgetConfig

export type NormalizedWidgetConfigByKind = {
  menu: NormalizedMenuWidgetConfig
  workspaces: NormalizedWorkspacesWidgetConfig
  tray: NormalizedTrayWidgetConfig
  clock: NormalizedClockWidgetConfig
  caffeine: NormalizedCaffeineWidgetConfig
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
