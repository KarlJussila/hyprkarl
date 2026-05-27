import type { BarEdge } from "./types"

export const BAR_LAYOUT_SOURCE_FILE = "layout.config.ts"
export const BAR_WIDGETS_SOURCE_FILE = "widgets.config.ts"

export type BarConfigSourceFile =
  | typeof BAR_LAYOUT_SOURCE_FILE
  | typeof BAR_WIDGETS_SOURCE_FILE

type BarConfigErrorArgs = {
  sourceFile: BarConfigSourceFile
  path: string
  message: string
  widgetId?: string
}

export class BarConfigError extends Error {
  readonly sourceFile: BarConfigSourceFile
  readonly path: string
  readonly widgetId?: string

  constructor({ sourceFile, path, message, widgetId }: BarConfigErrorArgs) {
    super(message)
    this.name = "BarConfigError"
    this.sourceFile = sourceFile
    this.path = path
    this.widgetId = widgetId
  }
}

export function isBarConfigError(error: unknown): error is BarConfigError {
  return error instanceof BarConfigError
}

export function formatBarConfigError(error: BarConfigError) {
  const location = error.path
    ? ` in ${error.sourceFile} at ${error.path}`
    : ` in ${error.sourceFile}`

  return `Bar config error${location}: ${error.message}`
}

export function summarizeBarConfigError(error: BarConfigError) {
  if (error.path) {
    return `Bar config error in ${error.sourceFile}: ${error.path}`
  }

  return `Bar config error in ${error.sourceFile}`
}

export function isBarEdge(value: unknown): value is BarEdge {
  return value === "top" || value === "bottom" || value === "left" || value === "right"
}

export function fallbackBarEdge(value: unknown): BarEdge {
  return isBarEdge(value) ? value : "top"
}
