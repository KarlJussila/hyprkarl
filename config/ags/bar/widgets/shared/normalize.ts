import {
  BAR_LAYOUT_SOURCE_FILE,
  BAR_WIDGETS_SOURCE_FILE,
  BarConfigError,
  type BarConfigSourceFile,
  isBarEdge,
} from "../../configError.ts"
import type {
  BarEdge,
  BatteryIndicatorMetrics,
  BatteryTooltipConfig,
  ClockDisplayConfig,
  DropdownAlign,
  DropdownConfig,
  NormalizedBatteryIndicatorMetrics,
  NormalizedBatteryTooltipConfig,
  NormalizedClockDisplayConfig,
  NormalizedCommandConfig,
  NormalizedDropdownConfig,
  NormalizedSwitchMetrics,
  NormalizedTrayRevealConfig,
  NormalizedWorkspaceVisibilityConfig,
  SwitchMetrics,
  TrayRevealConfig,
  WorkspaceVisibilityConfig,
} from "../../configuration.ts"

export type ValidationContext = {
  sourceFile: BarConfigSourceFile
  path: string
  widgetId?: string
}

export function fail(context: ValidationContext, message: string): never {
  throw new BarConfigError({
    ...context,
    message,
  })
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value)
}

export function layoutContext(path: string): ValidationContext {
  return {
    sourceFile: BAR_LAYOUT_SOURCE_FILE,
    path,
  }
}

export function widgetContext(id: string, path = ""): ValidationContext {
  return {
    sourceFile: BAR_WIDGETS_SOURCE_FILE,
    path: path ? `${id}.${path}` : id,
    widgetId: id,
  }
}

export function childContext(context: ValidationContext, child: string): ValidationContext {
  return {
    ...context,
    path: context.path ? `${context.path}.${child}` : child,
  }
}

export function indexContext(context: ValidationContext, index: number): ValidationContext {
  return {
    ...context,
    path: `${context.path}[${index}]`,
  }
}

export function normalizeObjectConfig(context: ValidationContext, value: unknown) {
  if (value === undefined) {
    return undefined
  }

  if (!isRecord(value)) {
    fail(context, "must be an object")
  }

  return value
}

export function normalizeStringValue(
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

export function normalizeOptionalCommand(
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

export function normalizeRequiredCommand(
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

export function normalizeBoolean(
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

export function normalizePositiveNumber(
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

export function normalizeNonNegativeNumber(
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

export function normalizeFiniteNumber(
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

export function normalizeUnitInterval(
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

export function normalizeIntegerList(
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

export function normalizeBarEdge(value: unknown): BarEdge {
  if (!isBarEdge(value)) {
    fail(layoutContext("edge"), 'must be "top", "bottom", "left", or "right"')
  }

  return value
}

export function normalizeLayoutWidgetId(context: ValidationContext, value: unknown) {
  if (typeof value !== "string" || value.trim().length === 0) {
    fail(context, "must reference a widget ID")
  }

  return value
}

export function normalizeOptionalLayoutWidgetId(context: ValidationContext, value: unknown) {
  if (value === undefined) {
    return undefined
  }

  return normalizeLayoutWidgetId(context, value)
}

export function normalizeDropdownAlign(
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

export function normalizeDropdownConfig(
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

export function normalizeCommands(
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

export function normalizeVisibility(
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

export function normalizeRevealConfig(
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

export function normalizeSwitchMetrics(
  id: string,
  metrics: SwitchMetrics | undefined,
  defaults: NormalizedSwitchMetrics,
  path = "advanced.switch",
): NormalizedSwitchMetrics {
  const context = widgetContext(id, path)
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

export function normalizeBatteryIndicatorMetrics(
  id: string,
  metrics: BatteryIndicatorMetrics | undefined,
  defaults: NormalizedBatteryIndicatorMetrics,
  path = "advanced.indicator",
): NormalizedBatteryIndicatorMetrics {
  const context = widgetContext(id, path)
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
    terminalHeight: normalizePositiveNumber(
      childContext(context, "terminalHeight"),
      rawMetrics?.terminalHeight,
      defaults.terminalHeight,
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

export function normalizeBatteryTooltipConfig(
  id: string,
  tooltip: BatteryTooltipConfig | undefined,
  defaults: NormalizedBatteryTooltipConfig,
): NormalizedBatteryTooltipConfig {
  const context = widgetContext(id, "tooltip")
  const rawTooltip = normalizeObjectConfig(context, tooltip)

  return {
    charging: normalizeStringValue(
      childContext(context, "charging"),
      rawTooltip?.charging,
      defaults.charging,
    ),
    discharging: normalizeStringValue(
      childContext(context, "discharging"),
      rawTooltip?.discharging,
      defaults.discharging,
    ),
    plugged: normalizeStringValue(
      childContext(context, "plugged"),
      rawTooltip?.plugged,
      defaults.plugged,
    ),
    fallback: normalizeStringValue(
      childContext(context, "fallback"),
      rawTooltip?.fallback,
      defaults.fallback,
    ),
  }
}

export function normalizeClockDisplay(
  id: string,
  display: ClockDisplayConfig | undefined,
  defaults: NormalizedClockDisplayConfig,
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
