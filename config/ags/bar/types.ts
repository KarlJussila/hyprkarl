import type { ResolvedBarWidgetDefinition } from "./widgets/catalog.ts"

/**
 * Shared bar configuration types.
 *
 * Casual users should usually edit:
 * - `config/layout.config.ts`
 * - `config/widgets.config.ts`
 * - `theme.scss`
 */

export type BarEdge = "top" | "bottom" | "left" | "right"

export type BarLayoutConfig = {
  edge: BarEdge
  showCornerCurves?: boolean
  autohide?: boolean
  exclusive?: boolean
  start: Array<string>
  center: {
    start: Array<string>
    center: Array<string>
    end: Array<string>
  }
  end: Array<string>
}

export type ResolvedBarConfiguration = {
  edge: BarEdge
  showCornerCurves: boolean
  autohide: boolean
  exclusive: boolean
  layout: {
    start: Array<string>
    center: {
      start: Array<string>
      center: Array<string>
      end: Array<string>
    }
    end: Array<string>
  }
  widgets: Record<string, ResolvedBarWidgetDefinition>
}
