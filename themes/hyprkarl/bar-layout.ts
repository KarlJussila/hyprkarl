import type { BarLayoutConfig } from "../types"

// Edit this file to rearrange the bar, move it to another screen edge, or restyle the islands.
//
// corners: each corner is "round" | "square" | "curve" (concave cutout). Corners are
//   named by long edge (screen/content) and cap (outer = facing a screen edge,
//   inner = facing the gaps between islands).
// borders: which island sides draw a border (screen/content long edges, outer/inner caps).
// dividers: separators between adjacent widgets within an island.
const layoutConfig = {
  edge: "top",
  autohide: false,
  exclusive: true,
  corners: {
    screenOuter: "square",
    screenInner: "curve",
    contentOuter: "square",
    contentInner: "round",
  },
  borders: {
    screen: false,
    content: true,
    outer: false,
    inner: true
  },
  dividers: true,
  margin: {
    screen: 0,
    outer: 0,
    content: 0
  },

  start: ["menu", "workspaces", "cpu", "gpu", "ram", "tray"],

  center: {
    start: ["recording"],
    center: ["clock"],
    end: ["caffeine"],
  },

  end: ["audio", "bluetooth", "network", "battery"],
} satisfies BarLayoutConfig

export default layoutConfig
