import { type BarEdge, type TrayDirection } from "./barPlacement"

export type BarWidgetName =
  | "menu"
  | "workspaces"
  | "tray"
  | "clock"
  | "caffeine"
  | "battery"

export type BarWidgetConfig =
  | BarWidgetName
  | {
      widget: "tray"
      direction?: TrayDirection
      mirrorTrigger?: boolean
    }

export type BarLayoutConfig = {
  start: Array<BarWidgetConfig>
  center: {
    start: Array<BarWidgetConfig>
    anchor: BarWidgetConfig
    end: Array<BarWidgetConfig>
  }
  end: Array<BarWidgetConfig>
}

// Edit this value to move the bar to another edge.
export const barEdge: BarEdge = "right"

// Edit these lists to rearrange widgets on the bar.
export const barLayout: BarLayoutConfig = {
  start: [
    "menu",
    "workspaces",
    { widget: "tray", direction: "end" },
  ],

  center: {
    // Before center widget
    start: [],

    // Center widget
    anchor: "clock",

    // After center widget
    end: [
      "caffeine",
    ],
  },

  end: [
    "battery",
  ],
}
