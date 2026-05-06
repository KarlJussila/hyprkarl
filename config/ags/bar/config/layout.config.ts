import type { BarLayoutConfig } from "../configuration"

// Edit this file to rearrange the bar or move it to another screen edge.
const layoutConfig = {
  edge: "right",

  start: [
    "menu",
    "workspaces",
    "tray",
  ],

  center: {
    start: [],
    anchor: "clock",
    end: [
      "caffeine",
    ],
  },

  end: [
    "battery",
  ],
} satisfies BarLayoutConfig

export default layoutConfig

