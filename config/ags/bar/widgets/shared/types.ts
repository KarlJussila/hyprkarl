import type { Gdk } from "ags/gtk4"
import type { BarPlacement } from "../../layout/placement.ts"

/**
 * Common shapes every widget can opt into.
 *
 * Widgets receive their config and a few rendering hints. Defaults live next
 * to the component; `mergeConfig` does a one-level-deep merge so users can
 * override either a whole nested object or just one of its keys.
 */

export type WidgetProps<TConfig> = {
  id: string
  config: TConfig
  placement: BarPlacement
  monitor: Gdk.Monitor
}

export type WidgetClicks = {
  primary?: string
  secondary?: string
  tertiary?: string
}

export type WidgetFlyout = {
  align: "start" | "center" | "end"
  gap: number
}

export const defaultFlyout: WidgetFlyout = { align: "center", gap: 0 }

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value)
}

/**
 * Shallow-or-one-level-deep merge. For each key in `overrides`, if both sides
 * are plain objects the values are merged one level deep; otherwise the
 * override wins. Arrays are replaced wholesale.
 *
 * Overrides are typed loosely (any compatible partial), since user configs
 * frequently pass partial nested objects that don't strictly match
 * `Partial<T>` at the nested level.
 */
export function mergeConfig<T extends Record<string, any>>(defaults: T, overrides?: any): T {
  if (!overrides) return defaults
  const out: Record<string, any> = { ...defaults }
  for (const key of Object.keys(overrides)) {
    const o = (overrides as Record<string, any>)[key]
    const d = (defaults as Record<string, any>)[key]
    if (o === undefined) continue
    if (isPlainObject(o) && isPlainObject(d)) {
      out[key] = { ...d, ...o }
    } else {
      out[key] = o
    }
  }
  return out as T
}
