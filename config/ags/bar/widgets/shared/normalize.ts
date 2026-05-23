import {
  BAR_LAYOUT_SOURCE_FILE,
  BAR_WIDGETS_SOURCE_FILE,
  BarConfigError,
  type BarConfigSourceFile,
  isBarEdge,
} from "../../configError.ts"
import type { BarEdge } from "../../configuration.ts"

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
  value: string | undefined,
  fallback: string,
): string {
  if (value === undefined) return fallback
  return value
}

export function normalizeOptionalCommand(
  context: ValidationContext,
  value: string | undefined,
  fallback?: string,
): string | undefined {
  if (value === undefined) return fallback
  if (value.trim().length === 0) {
    fail(context, "must be a non-empty command")
  }
  return value
}

export function normalizeRequiredCommand(
  context: ValidationContext,
  value: string | undefined,
  fallback: string,
): string {
  const command = value ?? fallback
  if (command.trim().length === 0) {
    fail(context, "must be a non-empty command")
  }
  return command
}

export function normalizeBoolean(
  context: ValidationContext,
  value: boolean | undefined,
  fallback: boolean,
): boolean {
  if (value === undefined) return fallback
  if (typeof value !== "boolean") fail(context, "must be true or false")
  return value
}

export function normalizePositiveNumber(
  context: ValidationContext,
  value: number | undefined,
  fallback: number,
): number {
  if (value === undefined) return fallback
  if (!Number.isFinite(value) || value <= 0) {
    fail(context, "must be a positive number")
  }
  return value
}

export function normalizeNonNegativeNumber(
  context: ValidationContext,
  value: number | undefined,
  fallback: number,
): number {
  if (value === undefined) return fallback
  if (!Number.isFinite(value) || value < 0) {
    fail(context, "must be zero or greater")
  }
  return value
}

export function normalizeFiniteNumber(
  context: ValidationContext,
  value: number | undefined,
  fallback: number,
): number {
  if (value === undefined) return fallback
  if (!Number.isFinite(value)) {
    fail(context, "must be a finite number")
  }
  return value
}

export function normalizeUnitInterval(
  context: ValidationContext,
  value: number | undefined,
  fallback: number,
): number {
  if (value === undefined) return fallback
  if (!Number.isFinite(value) || value < 0 || value > 1) {
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

export type RevealConfig = {
  durationMs?: number
}

export type NormalizedRevealConfig = {
  durationMs: number
}

export function normalizeRevealConfig(
  ctx: ValidationContext,
  reveal: RevealConfig | undefined,
  defaults: NormalizedRevealConfig,
): NormalizedRevealConfig {
  const rawReveal = normalizeObjectConfig(ctx, reveal) as RevealConfig | undefined
  return {
    durationMs: normalizePositiveNumber(childContext(ctx, "durationMs"), rawReveal?.durationMs, defaults.durationMs),
  }
}

export type FormatConfig = {
  primary?: string
  alt?: string
  vertical?: string
  verticalAlt?: string
}

export type NormalizedFormatConfig = {
  primary: string
  alt: string
  vertical: string
  verticalAlt: string
}

export function normalizeFormatConfig(
  ctx: ValidationContext,
  value: FormatConfig | undefined,
  defaults: NormalizedFormatConfig,
): NormalizedFormatConfig {
  const raw = normalizeObjectConfig(ctx, value) as FormatConfig | undefined
  return {
    primary: normalizeStringValue(childContext(ctx, "primary"), raw?.primary, defaults.primary),
    alt: normalizeStringValue(childContext(ctx, "alt"), raw?.alt, defaults.alt),
    vertical: normalizeStringValue(childContext(ctx, "vertical"), raw?.vertical, defaults.vertical),
    verticalAlt: normalizeStringValue(childContext(ctx, "verticalAlt"), raw?.verticalAlt, defaults.verticalAlt),
  }
}

export type DecimalsConfig = {
  primary?: number
  alt?: number
  vertical?: number
  verticalAlt?: number
}

export type NormalizedDecimalsConfig = {
  primary: number
  alt: number
  vertical: number
  verticalAlt: number
}

export function normalizeDecimalsConfig(
  ctx: ValidationContext,
  value: DecimalsConfig | undefined,
  defaults: NormalizedDecimalsConfig,
): NormalizedDecimalsConfig {
  const raw = normalizeObjectConfig(ctx, value) as DecimalsConfig | undefined
  const primary = normalizeNonNegativeNumber(childContext(ctx, "primary"), raw?.primary, defaults.primary)
  const alt = normalizeNonNegativeNumber(childContext(ctx, "alt"), raw?.alt, primary)
  const vertical = normalizeNonNegativeNumber(childContext(ctx, "vertical"), raw?.vertical, primary)
  const verticalAlt = normalizeNonNegativeNumber(childContext(ctx, "verticalAlt"), raw?.verticalAlt, vertical)
  return { primary, alt, vertical, verticalAlt }
}

export function normalizeStringRecord<T extends Record<string, string>>(
  ctx: ValidationContext,
  value: Partial<T> | undefined,
  defaults: T,
): T {
  const raw = normalizeObjectConfig(ctx, value) as Partial<T> | undefined
  const result: Record<string, string> = {}
  for (const key of Object.keys(defaults)) {
    result[key] = normalizeStringValue(childContext(ctx, key), raw?.[key], defaults[key])
  }
  return result as T
}
