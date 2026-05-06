import {
  BAR_LAYOUT_SOURCE_FILE,
  BAR_WIDGETS_SOURCE_FILE,
  BarConfigError,
  type BarConfigSourceFile,
  isBarEdge,
} from "../configError.ts"
import type {
  BarEdge,
  BarLayoutConfig,
  BarWidgetDefinition,
  BarWidgetDefinitions,
  BatteryIndicatorMetrics,
  DropdownAlign,
  DropdownConfig,
  NormalizedBarWidgetDefinition,
  NormalizedBatteryIndicatorMetrics,
  NormalizedBatteryWidgetConfig,
  NormalizedCaffeineWidgetConfig,
  NormalizedClockWidgetConfig,
  NormalizedCommandConfig,
  NormalizedDropdownConfig,
  NormalizedMenuWidgetConfig,
  NormalizedSwitchMetrics,
  NormalizedTrayRevealConfig,
  NormalizedTrayWidgetConfig,
  NormalizedWorkspaceVisibilityConfig,
  NormalizedWorkspacesWidgetConfig,
  ResolvedBarConfiguration,
  SwitchMetrics,
  TrayRevealConfig,
  WorkspaceVisibilityConfig,
} from "../configuration.ts"

type MenuWidgetDefinition = Extract<BarWidgetDefinition, { kind: "menu" }>
type WorkspacesWidgetDefinition = Extract<BarWidgetDefinition, { kind: "workspaces" }>
type TrayWidgetDefinition = Extract<BarWidgetDefinition, { kind: "tray" }>
type ClockWidgetDefinition = Extract<BarWidgetDefinition, { kind: "clock" }>
type CaffeineWidgetDefinition = Extract<BarWidgetDefinition, { kind: "caffeine" }>
type BatteryWidgetDefinition = Extract<BarWidgetDefinition, { kind: "battery" }>

type RegistryEntry<
  TDefinition extends BarWidgetDefinition,
  TNormalized extends NormalizedBarWidgetDefinition,
> = {
  defaults: Omit<TNormalized, "kind">
  normalize: (id: string, definition: TDefinition) => TNormalized
}

type DynamicWorkspacesConfig = Extract<NormalizedWorkspacesWidgetConfig, { mode: "dynamic" }>

type WidgetDefinitionRegistry = {
  menu: RegistryEntry<MenuWidgetDefinition, NormalizedMenuWidgetConfig>
  workspaces: RegistryEntry<
    WorkspacesWidgetDefinition,
    DynamicWorkspacesConfig | Extract<NormalizedWorkspacesWidgetConfig, { mode: "fixed" }>
  >
  tray: RegistryEntry<TrayWidgetDefinition, NormalizedTrayWidgetConfig>
  clock: RegistryEntry<ClockWidgetDefinition, NormalizedClockWidgetConfig>
  caffeine: RegistryEntry<CaffeineWidgetDefinition, NormalizedCaffeineWidgetConfig>
  battery: RegistryEntry<BatteryWidgetDefinition, NormalizedBatteryWidgetConfig>
}

type ValidationContext = {
  sourceFile: BarConfigSourceFile
  path: string
  widgetId?: string
}

type LayoutReference = {
  path: string
  widgetId: string
}

type ResolvedLayoutConfig = ResolvedBarConfiguration["layout"] & {
  edge: BarEdge
}

function fail(context: ValidationContext, message: string): never {
  throw new BarConfigError({
    ...context,
    message,
  })
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value)
}

function layoutContext(path: string): ValidationContext {
  return {
    sourceFile: BAR_LAYOUT_SOURCE_FILE,
    path,
  }
}

function widgetContext(id: string, path = ""): ValidationContext {
  return {
    sourceFile: BAR_WIDGETS_SOURCE_FILE,
    path: path ? `${id}.${path}` : id,
    widgetId: id,
  }
}

function childContext(context: ValidationContext, child: string): ValidationContext {
  return {
    ...context,
    path: context.path ? `${context.path}.${child}` : child,
  }
}

function indexContext(context: ValidationContext, index: number): ValidationContext {
  return {
    ...context,
    path: `${context.path}[${index}]`,
  }
}

function normalizeObjectConfig(context: ValidationContext, value: unknown) {
  if (value === undefined) {
    return undefined
  }

  if (!isRecord(value)) {
    fail(context, "must be an object")
  }

  return value
}

function normalizeStringValue(
  context: ValidationContext,
  value: unknown,
  fallback: string,
) {
  if (value === undefined) {
    return fallback
  }

  if (typeof value !== "string") {
    fail(context, "must be a string")
  }

  return value
}

function normalizeOptionalCommand(
  context: ValidationContext,
  value: unknown,
  fallback?: string,
) {
  if (value === undefined) {
    return fallback
  }

  if (typeof value !== "string" || value.trim().length === 0) {
    fail(context, "must be a non-empty command")
  }

  return value
}

function normalizeRequiredCommand(
  context: ValidationContext,
  value: unknown,
  fallback: string,
) {
  const command = value ?? fallback
  if (typeof command !== "string" || command.trim().length === 0) {
    fail(context, "must be a non-empty command")
  }

  return command
}

function normalizeBoolean(
  context: ValidationContext,
  value: unknown,
  fallback: boolean,
) {
  if (value === undefined) {
    return fallback
  }

  if (typeof value !== "boolean") {
    fail(context, "must be true or false")
  }

  return value
}

function isFiniteNumber(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value)
}

function normalizePositiveNumber(
  context: ValidationContext,
  value: unknown,
  fallback: number,
) {
  if (value === undefined) return fallback
  if (!isFiniteNumber(value) || value <= 0) {
    fail(context, "must be a positive number")
  }

  return value
}

function normalizeNonNegativeNumber(
  context: ValidationContext,
  value: unknown,
  fallback: number,
) {
  if (value === undefined) return fallback
  if (!isFiniteNumber(value) || value < 0) {
    fail(context, "must be zero or greater")
  }

  return value
}

function normalizeFiniteNumber(
  context: ValidationContext,
  value: unknown,
  fallback: number,
) {
  if (value === undefined) return fallback
  if (!isFiniteNumber(value)) {
    fail(context, "must be a finite number")
  }

  return value
}

function normalizeUnitInterval(
  context: ValidationContext,
  value: unknown,
  fallback: number,
) {
  if (value === undefined) return fallback
  if (!isFiniteNumber(value) || value < 0 || value > 1) {
    fail(context, "must be between 0 and 1")
  }

  return value
}

function normalizeIntegerList(
  context: ValidationContext,
  ids: unknown,
  allowEmpty = true,
) {
  const list = ids ?? []
  if (!Array.isArray(list)) {
    fail(context, "must be a list of positive integers")
  }

  const seen = new Set<number>()
  const normalized: Array<number> = []

  list.forEach((id, index) => {
    if (!Number.isInteger(id) || id <= 0) {
      fail(indexContext(context, index), "must be a positive integer")
    }

    if (!seen.has(id)) {
      seen.add(id)
      normalized.push(id)
    }
  })

  if (!allowEmpty && normalized.length === 0) {
    fail(context, "must include at least one workspace ID")
  }

  return normalized
}

function normalizeBarEdge(value: unknown): BarEdge {
  if (!isBarEdge(value)) {
    fail(layoutContext("edge"), 'must be "top", "bottom", "left", or "right"')
  }

  return value
}

function normalizeLayoutWidgetId(context: ValidationContext, value: unknown) {
  if (typeof value !== "string" || value.trim().length === 0) {
    fail(context, "must reference a widget ID")
  }

  return value
}

function normalizeLayoutIdList(path: string, value: unknown) {
  const context = layoutContext(path)
  if (!Array.isArray(value)) {
    fail(context, "must be an array of widget IDs")
  }

  return value.map((widgetId, index) => normalizeLayoutWidgetId(indexContext(context, index), widgetId))
}

function normalizeLayoutConfig(layoutConfig: BarLayoutConfig): ResolvedLayoutConfig {
  const rawLayout = layoutConfig as unknown
  if (!isRecord(rawLayout)) {
    fail(layoutContext(""), "must export a layout object")
  }

  const center = rawLayout.center
  if (!isRecord(center)) {
    fail(layoutContext("center"), "must be an object")
  }

  return {
    edge: normalizeBarEdge(rawLayout.edge),
    start: normalizeLayoutIdList("start", rawLayout.start),
    center: {
      start: normalizeLayoutIdList("center.start", center.start),
      anchor: normalizeLayoutWidgetId(layoutContext("center.anchor"), center.anchor),
      end: normalizeLayoutIdList("center.end", center.end),
    },
    end: normalizeLayoutIdList("end", rawLayout.end),
  }
}

function normalizeDropdownAlign(
  context: ValidationContext,
  value: unknown,
  fallback: DropdownAlign,
) {
  const align = value ?? fallback
  if (align !== "start" && align !== "center" && align !== "end") {
    fail(context, 'must be "start", "center", or "end"')
  }

  return align
}

function normalizeDropdownConfig(
  id: string,
  config: DropdownConfig | undefined,
  defaults: NormalizedDropdownConfig,
): NormalizedDropdownConfig {
  const context = widgetContext(id, "dropdown")
  const rawConfig = normalizeObjectConfig(context, config)

  return {
    enabled: normalizeBoolean(
      childContext(context, "enabled"),
      rawConfig?.enabled,
      defaults.enabled,
    ),
    align: normalizeDropdownAlign(
      childContext(context, "align"),
      rawConfig?.align,
      defaults.align,
    ),
    gap: normalizeNonNegativeNumber(
      childContext(context, "gap"),
      rawConfig?.gap,
      defaults.gap,
    ),
  }
}

function normalizeCommands(
  id: string,
  commands: { primary?: string; secondary?: string } | undefined,
  defaults: NormalizedCommandConfig,
): NormalizedCommandConfig {
  const context = widgetContext(id, "commands")
  const rawCommands = normalizeObjectConfig(context, commands)

  return {
    primary: normalizeRequiredCommand(
      childContext(context, "primary"),
      rawCommands?.primary,
      defaults.primary,
    ),
    secondary: normalizeOptionalCommand(
      childContext(context, "secondary"),
      rawCommands?.secondary,
      defaults.secondary,
    ),
  }
}

function normalizeVisibility(
  id: string,
  visibility: WorkspaceVisibilityConfig | undefined,
  defaults: NormalizedWorkspaceVisibilityConfig,
): NormalizedWorkspaceVisibilityConfig {
  const context = widgetContext(id, "visibility")
  const rawVisibility = normalizeObjectConfig(context, visibility)

  return {
    alwaysShow: normalizeIntegerList(
      childContext(context, "alwaysShow"),
      rawVisibility?.alwaysShow ?? defaults.alwaysShow,
      true,
    ),
    includeFocused: normalizeBoolean(
      childContext(context, "includeFocused"),
      rawVisibility?.includeFocused,
      defaults.includeFocused,
    ),
    includeOccupied: normalizeBoolean(
      childContext(context, "includeOccupied"),
      rawVisibility?.includeOccupied,
      defaults.includeOccupied,
    ),
    excludeSpecial: normalizeBoolean(
      childContext(context, "excludeSpecial"),
      rawVisibility?.excludeSpecial,
      defaults.excludeSpecial,
    ),
  }
}

function normalizeRevealConfig(
  id: string,
  reveal: TrayRevealConfig | undefined,
  defaults: NormalizedTrayRevealConfig,
): NormalizedTrayRevealConfig {
  const context = widgetContext(id, "reveal")
  const rawReveal = normalizeObjectConfig(context, reveal)

  return {
    durationMs: normalizePositiveNumber(
      childContext(context, "durationMs"),
      rawReveal?.durationMs,
      defaults.durationMs,
    ),
  }
}

function normalizeSwitchMetrics(
  id: string,
  metrics: SwitchMetrics | undefined,
  defaults: NormalizedSwitchMetrics,
): NormalizedSwitchMetrics {
  const context = widgetContext(id, "switch")
  const rawMetrics = normalizeObjectConfig(context, metrics)

  return {
    thumbSize: normalizePositiveNumber(
      childContext(context, "thumbSize"),
      rawMetrics?.thumbSize,
      defaults.thumbSize,
    ),
    trackHeight: normalizePositiveNumber(
      childContext(context, "trackHeight"),
      rawMetrics?.trackHeight,
      defaults.trackHeight,
    ),
    trackLength: normalizePositiveNumber(
      childContext(context, "trackLength"),
      rawMetrics?.trackLength,
      defaults.trackLength,
    ),
    thumbPadding: normalizeNonNegativeNumber(
      childContext(context, "thumbPadding"),
      rawMetrics?.thumbPadding,
      defaults.thumbPadding,
    ),
    glyphOffsetX: normalizeFiniteNumber(
      childContext(context, "glyphOffsetX"),
      rawMetrics?.glyphOffsetX,
      defaults.glyphOffsetX,
    ),
    glyphOffsetY: normalizeFiniteNumber(
      childContext(context, "glyphOffsetY"),
      rawMetrics?.glyphOffsetY,
      defaults.glyphOffsetY,
    ),
    borderWidth: normalizeNonNegativeNumber(
      childContext(context, "borderWidth"),
      rawMetrics?.borderWidth,
      defaults.borderWidth,
    ),
    fontSize: normalizePositiveNumber(
      childContext(context, "fontSize"),
      rawMetrics?.fontSize,
      defaults.fontSize,
    ),
    fontFamily: normalizeStringValue(
      childContext(context, "fontFamily"),
      rawMetrics?.fontFamily,
      defaults.fontFamily,
    ),
  }
}

function normalizeBatteryIndicatorMetrics(
  id: string,
  metrics: BatteryIndicatorMetrics | undefined,
  defaults: NormalizedBatteryIndicatorMetrics,
): NormalizedBatteryIndicatorMetrics {
  const context = widgetContext(id, "indicator")
  const rawMetrics = normalizeObjectConfig(context, metrics)

  return {
    width: normalizePositiveNumber(
      childContext(context, "width"),
      rawMetrics?.width,
      defaults.width,
    ),
    height: normalizePositiveNumber(
      childContext(context, "height"),
      rawMetrics?.height,
      defaults.height,
    ),
    borderWidth: normalizeNonNegativeNumber(
      childContext(context, "borderWidth"),
      rawMetrics?.borderWidth,
      defaults.borderWidth,
    ),
    terminalWidth: normalizePositiveNumber(
      childContext(context, "terminalWidth"),
      rawMetrics?.terminalWidth,
      defaults.terminalWidth,
    ),
    terminalHeightRatio: normalizeUnitInterval(
      childContext(context, "terminalHeightRatio"),
      rawMetrics?.terminalHeightRatio,
      defaults.terminalHeightRatio,
    ),
    chargingGlyph: normalizeStringValue(
      childContext(context, "chargingGlyph"),
      rawMetrics?.chargingGlyph,
      defaults.chargingGlyph,
    ),
    chargingGlyphFontSize: normalizePositiveNumber(
      childContext(context, "chargingGlyphFontSize"),
      rawMetrics?.chargingGlyphFontSize,
      defaults.chargingGlyphFontSize,
    ),
    chargingGlyphFontFamily: normalizeStringValue(
      childContext(context, "chargingGlyphFontFamily"),
      rawMetrics?.chargingGlyphFontFamily,
      defaults.chargingGlyphFontFamily,
    ),
  }
}

function normalizeTrayDirection(id: string, value: unknown, fallback: "start" | "end") {
  const direction = value ?? fallback
  if (direction !== "start" && direction !== "end") {
    fail(widgetContext(id, "direction"), 'must be "start" or "end"')
  }

  return direction
}

function validateWorkspaceMode(id: string, value: unknown) {
  if (value === undefined || value === "dynamic" || value === "fixed") {
    return
  }

  fail(widgetContext(id, "mode"), 'must be "dynamic" or "fixed"')
}

function normalizeClockDisplay(
  id: string,
  display: ClockWidgetDefinition["display"],
  defaults: NormalizedClockWidgetConfig["display"],
) {
  const context = widgetContext(id, "display")
  const rawDisplay = normalizeObjectConfig(context, display)
  const rawVertical = normalizeObjectConfig(childContext(context, "vertical"), rawDisplay?.vertical)

  return {
    horizontal: normalizeStringValue(
      childContext(context, "horizontal"),
      rawDisplay?.horizontal,
      defaults.horizontal,
    ),
    vertical: {
      top: normalizeStringValue(
        childContext(context, "vertical.top"),
        rawVertical?.top,
        defaults.vertical.top,
      ),
      middle: normalizeStringValue(
        childContext(context, "vertical.middle"),
        rawVertical?.middle,
        defaults.vertical.middle,
      ),
      bottom: normalizeStringValue(
        childContext(context, "vertical.bottom"),
        rawVertical?.bottom,
        defaults.vertical.bottom,
      ),
    },
  }
}

const menuDefaults: Omit<NormalizedMenuWidgetConfig, "kind"> = {
  icon: "",
  commands: {
    primary: "hyprkarl-menu",
  },
}

const workspacesDefaults: Omit<DynamicWorkspacesConfig, "kind"> = {
  mode: "dynamic",
  visibility: {
    alwaysShow: [1],
    includeFocused: true,
    includeOccupied: true,
    excludeSpecial: true,
  },
}

const trayDefaults: Omit<NormalizedTrayWidgetConfig, "kind"> = {
  direction: "start",
  mirrorTrigger: false,
  reveal: {
    durationMs: 220,
  },
}

const clockDefaults: Omit<NormalizedClockWidgetConfig, "kind"> = {
  display: {
    horizontal: "%a %-I:%M %p",
    vertical: {
      top: "%I",
      middle: "%M",
      bottom: "%p",
    },
  },
  dropdown: {
    enabled: true,
    align: "center",
    gap: 0,
  },
}

const caffeineDefaults: Omit<NormalizedCaffeineWidgetConfig, "kind"> = {
  glyph: "",
  command: "hyprkarl-caffeine",
  switch: {
    thumbSize: 16,
    trackHeight: 12,
    trackLength: 24,
    thumbPadding: 7,
    glyphOffsetX: 0,
    glyphOffsetY: 0,
    borderWidth: 2,
    fontSize: 8,
    fontFamily: "JetBrains Mono Nerd Font Propo",
  },
}

const batteryDefaults: Omit<NormalizedBatteryWidgetConfig, "kind"> = {
  showPercentage: true,
  lowThreshold: 0.15,
  dropdown: {
    enabled: true,
    align: "center",
    gap: 0,
  },
  indicator: {
    width: 16,
    height: 10,
    borderWidth: 2,
    terminalWidth: 3,
    terminalHeightRatio: 0.4,
    chargingGlyph: "󱐋",
    chargingGlyphFontSize: 8,
    chargingGlyphFontFamily: "JetBrains Mono Nerd Font Propo",
  },
}

export const widgetDefinitionRegistry: WidgetDefinitionRegistry = {
  menu: {
    defaults: menuDefaults,
    normalize: (id, definition) => {
      return {
        kind: "menu",
        icon: normalizeStringValue(
          widgetContext(id, "icon"),
          definition.icon,
          menuDefaults.icon,
        ),
        commands: normalizeCommands(id, definition.commands, menuDefaults.commands),
      }
    },
  },

  workspaces: {
    defaults: workspacesDefaults,
    normalize: (id, definition) => {
      validateWorkspaceMode(id, definition.mode)

      if (definition.mode === "fixed") {
        return {
          kind: "workspaces",
          mode: "fixed",
          ids: normalizeIntegerList(
            widgetContext(id, "ids"),
            definition.ids,
            false,
          ),
        }
      }

      return {
        kind: "workspaces",
        mode: "dynamic",
        visibility: normalizeVisibility(
          id,
          definition.visibility,
          workspacesDefaults.visibility,
        ),
      }
    },
  },

  tray: {
    defaults: trayDefaults,
    normalize: (id, definition) => {
      return {
        kind: "tray",
        direction: normalizeTrayDirection(
          id,
          definition.direction,
          trayDefaults.direction,
        ),
        mirrorTrigger: normalizeBoolean(
          widgetContext(id, "mirrorTrigger"),
          definition.mirrorTrigger,
          trayDefaults.mirrorTrigger,
        ),
        reveal: normalizeRevealConfig(id, definition.reveal, trayDefaults.reveal),
      }
    },
  },

  clock: {
    defaults: clockDefaults,
    normalize: (id, definition) => {
      return {
        kind: "clock",
        display: normalizeClockDisplay(id, definition.display, clockDefaults.display),
        dropdown: normalizeDropdownConfig(id, definition.dropdown, clockDefaults.dropdown),
      }
    },
  },

  caffeine: {
    defaults: caffeineDefaults,
    normalize: (id, definition) => {
      return {
        kind: "caffeine",
        glyph: normalizeStringValue(
          widgetContext(id, "glyph"),
          definition.glyph,
          caffeineDefaults.glyph,
        ),
        command: normalizeRequiredCommand(
          widgetContext(id, "command"),
          definition.command,
          caffeineDefaults.command,
        ),
        switch: normalizeSwitchMetrics(id, definition.switch, caffeineDefaults.switch),
      }
    },
  },

  battery: {
    defaults: batteryDefaults,
    normalize: (id, definition) => {
      return {
        kind: "battery",
        showPercentage: normalizeBoolean(
          widgetContext(id, "showPercentage"),
          definition.showPercentage,
          batteryDefaults.showPercentage,
        ),
        lowThreshold: normalizeUnitInterval(
          widgetContext(id, "lowThreshold"),
          definition.lowThreshold,
          batteryDefaults.lowThreshold,
        ),
        dropdown: normalizeDropdownConfig(id, definition.dropdown, batteryDefaults.dropdown),
        indicator: normalizeBatteryIndicatorMetrics(
          id,
          definition.indicator,
          batteryDefaults.indicator,
        ),
      }
    },
  },
}

function normalizeWidgetDefinition(id: string, definition: unknown) {
  if (!isRecord(definition)) {
    fail(widgetContext(id), "must be an object")
  }

  switch (definition.kind) {
    case "menu":
      return widgetDefinitionRegistry.menu.normalize(id, definition as MenuWidgetDefinition)
    case "workspaces":
      return widgetDefinitionRegistry.workspaces.normalize(id, definition as WorkspacesWidgetDefinition)
    case "tray":
      return widgetDefinitionRegistry.tray.normalize(id, definition as TrayWidgetDefinition)
    case "clock":
      return widgetDefinitionRegistry.clock.normalize(id, definition as ClockWidgetDefinition)
    case "caffeine":
      return widgetDefinitionRegistry.caffeine.normalize(id, definition as CaffeineWidgetDefinition)
    case "battery":
      return widgetDefinitionRegistry.battery.normalize(id, definition as BatteryWidgetDefinition)
    default:
      fail(
        widgetContext(id, "kind"),
        `unknown widget kind "${String(definition.kind)}"`,
      )
  }
}

function collectLayoutReferences(layoutConfig: ResolvedLayoutConfig): Array<LayoutReference> {
  return [
    ...layoutConfig.start.map((widgetId, index) => ({
      path: `start[${index}]`,
      widgetId,
    })),
    ...layoutConfig.center.start.map((widgetId, index) => ({
      path: `center.start[${index}]`,
      widgetId,
    })),
    {
      path: "center.anchor",
      widgetId: layoutConfig.center.anchor,
    },
    ...layoutConfig.center.end.map((widgetId, index) => ({
      path: `center.end[${index}]`,
      widgetId,
    })),
    ...layoutConfig.end.map((widgetId, index) => ({
      path: `end[${index}]`,
      widgetId,
    })),
  ]
}

export function normalizeBarConfiguration(
  layoutConfig: BarLayoutConfig,
  widgetDefinitions: BarWidgetDefinitions,
): ResolvedBarConfiguration {
  const resolvedLayout = normalizeLayoutConfig(layoutConfig)

  const rawWidgetDefinitions = widgetDefinitions as unknown
  if (!isRecord(rawWidgetDefinitions)) {
    fail(
      {
        sourceFile: BAR_WIDGETS_SOURCE_FILE,
        path: "",
      },
      "must export a widget definition record",
    )
  }

  const layoutReferences = collectLayoutReferences(resolvedLayout)
  const seenLayoutIds = new Set<string>()

  layoutReferences.forEach(({ widgetId, path }) => {
    if (seenLayoutIds.has(widgetId)) {
      fail(layoutContext(path), `widget ID "${widgetId}" is used more than once in the layout`)
    }

    seenLayoutIds.add(widgetId)

    if (!(widgetId in rawWidgetDefinitions)) {
      fail(layoutContext(path), `references unknown widget ID "${widgetId}"`)
    }
  })

  const normalizedWidgets = Object.fromEntries(
    Object.entries(rawWidgetDefinitions).map(([id, definition]) => [
      id,
      normalizeWidgetDefinition(id, definition),
    ]),
  ) as Record<string, NormalizedBarWidgetDefinition>

  return {
    edge: resolvedLayout.edge,
    layout: {
      start: [...resolvedLayout.start],
      center: {
        start: [...resolvedLayout.center.start],
        anchor: resolvedLayout.center.anchor,
        end: [...resolvedLayout.center.end],
      },
      end: [...resolvedLayout.end],
    },
    widgets: normalizedWidgets,
  }
}
