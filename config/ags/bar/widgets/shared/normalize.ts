import {
  BAR_LAYOUT_SOURCE_FILE,
  BAR_WIDGETS_SOURCE_FILE,
  BarConfigError,
  type BarConfigSourceFile,
  isBarEdge,
} from "../../configError.ts"
import type { BarEdge } from "../../types.ts"

export type ValidationContext = {
  sourceFile: BarConfigSourceFile
  path: string
  widgetId?: string
}

export type FieldNormalizer<TRaw, TResolved = TRaw> = (
  ctx: ValidationContext,
  val: TRaw | undefined,
  fallback: TResolved,
) => TResolved

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

type SchemaRaw<TSchema> = {
  [K in keyof TSchema]?: TSchema[K] extends FieldNormalizer<infer R, any> ? R : never
}

type SchemaResolved<TSchema> = {
  [K in keyof TSchema]: TSchema[K] extends FieldNormalizer<any, infer N> ? N : never
}

export function composeObject<TSchema extends Record<string, FieldNormalizer<any, any>>>(
  schema: TSchema,
): FieldNormalizer<SchemaRaw<TSchema>, SchemaResolved<TSchema>> {
  return (ctx, value, defaults) => {
    const raw = normalizeObjectConfig(ctx, value) as Record<string, unknown> | undefined
    const result: Record<string, unknown> = {}
    for (const field of Object.keys(schema)) {
      const normalizer = schema[field] as FieldNormalizer<unknown, unknown>
      result[field] = normalizer(
        childContext(ctx, field),
        raw?.[field],
        (defaults as Record<string, unknown>)[field],
      )
    }
    return result as SchemaResolved<TSchema>
  }
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

export const normalizeRevealConfig = composeObject({
  durationMs: normalizePositiveNumber,
})

export type NormalizedRevealConfig = ReturnType<typeof normalizeRevealConfig>
export type RevealConfig = Parameters<typeof normalizeRevealConfig>[1]

export const normalizeFormatConfig = composeObject({
  primary: normalizeStringValue,
  alt: normalizeStringValue,
  vertical: normalizeStringValue,
  verticalAlt: normalizeStringValue,
})

export type NormalizedFormatConfig = ReturnType<typeof normalizeFormatConfig>
export type FormatConfig = Parameters<typeof normalizeFormatConfig>[1]

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

export const normalizeSimpleTooltipConfig = composeObject({
  text: normalizeStringValue,
})

export type NormalizedSimpleTooltipConfig = ReturnType<typeof normalizeSimpleTooltipConfig>
export type SimpleTooltipConfig = Parameters<typeof normalizeSimpleTooltipConfig>[1]

const normalizeClickCommand: FieldNormalizer<string, string | undefined> = (ctx, value, fallback) => {
  if (value === undefined) return fallback
  if (value.length > 0 && value.trim().length === 0) {
    fail(ctx, 'must be a command, a token like "{name}", or "" to disable the click')
  }
  return value
}

export const normalizeClickCommandsConfig = composeObject({
  primary: normalizeClickCommand,
  secondary: normalizeClickCommand,
  tertiary: normalizeClickCommand,
})

export type NormalizedClickCommandsConfig = ReturnType<typeof normalizeClickCommandsConfig>
export type ClickCommandsConfig = Parameters<typeof normalizeClickCommandsConfig>[1]
