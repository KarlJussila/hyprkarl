// A single overlaid glyph used by the battery and switch indicators.
// `glyphOffset` is a [x, y] nudge in base pixels, applied at render time.
export type Glyph = {
  glyph: string
  glyphOffset: [number, number]
}

// Back-compat alias; old code referred to this as Normalized*.
export type NormalizedGlyph = Glyph
