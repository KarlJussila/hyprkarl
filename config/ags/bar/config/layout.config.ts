import type { BarLayoutConfig } from "../types"

// Edit this file to rearrange the bar, move it to another screen edge, or toggle decorative corner curves.
const layoutConfig = {
  edge: "top",
  autohide: false,
  exclusive: true,
  showCornerCurves: true,

  start: [
    "menu",
    "workspaces",
    "cpu",
    "ram",
    "tray",
  ],

  center: {
    start: [
      "recording",
    ],
    center: [
      "clock",
    ],
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
