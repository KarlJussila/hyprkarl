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
  autohide: true,
  exclusive: true,
  corners: {
    screenOuter: "square",
    screenInner: "round",
    contentOuter: "square",
    contentInner: "round",
  },
  borders: { screen: true, content: true, outer: true, inner: true },
  dividers: true,
  margin: { screen: 0, outer: 0, content: 0 },

  start: ["menu", "workspaces", "cpu", "ram", "tray"],

  center: {
    start: ["recording"],
    center: ["clock"],
    end: ["caffeine"],
  },

  end: ["audio", "bluetooth", "network", "battery"],
} satisfies BarLayoutConfig

export default layoutConfig
