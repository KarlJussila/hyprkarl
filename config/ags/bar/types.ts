/**
 * Shared bar configuration types.
 *
 * Casual users should usually edit:
 * - `config/layout.config.ts`
 * - `config/widgets.config.ts`
 * - `theme.scss`
 */

export type BarEdge = "top" | "bottom" | "left" | "right"

// Margins named relative to the bar, so they map across every edge:
//   screen  — gap on the docked edge (between the bar and its screen edge)
//   content — gap on the opposite edge (between the bar and the windows it pushes away)
//   outer   — gap at both ends of the bar, along its length
// All are reserved space, same as today's margin; they just split it by side.
export type BarMargin = {
  screen?: number
  outer?: number
  content?: number
}

// How a single island corner is drawn. "curve" renders the decorative concave
// cutout and only has an anchor on the screen-inner corners (the gap-facing
// screen corner of every island — set via `screenInner`); on any other corner
// "curve" falls back to "square".
export type CornerStyle = "round" | "square" | "curve"

// Corners are named by which long edge (screen/content) and which cap
// (outer = facing a screen edge, inner = facing the gap between islands) they
// sit on, so the same name maps correctly across every bar edge and island.
export type IslandCorners = {
  screenOuter?: CornerStyle
  screenInner?: CornerStyle
  contentOuter?: CornerStyle
  contentInner?: CornerStyle
}

export type ResolvedIslandCorners = Required<IslandCorners>

// Which island sides get a border. `outer`/`inner` are the short caps;
// `screen`/`content` are the long edges.
export type IslandBorders = {
  screen?: boolean
  content?: boolean
  outer?: boolean
  inner?: boolean
}

export type BarLayoutConfig = {
  edge: BarEdge
  corners?: IslandCorners
  borders?: IslandBorders
  dividers?: boolean
  margin?: number | BarMargin
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
