import type { BarLayoutConfig } from "../configuration"

// Edit this file to rearrange the bar, move it to another screen edge, or toggle decorative corner curves.
const layoutConfig = {
  edge: "top",
  showCornerCurves: true,

  start: [
    "menu",
    "workspaces",
    "cpu",
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
    "audio",
    "bluetooth",
    "network",
    "battery",
  ],
} satisfies BarLayoutConfig

export default layoutConfig
