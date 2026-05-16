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
