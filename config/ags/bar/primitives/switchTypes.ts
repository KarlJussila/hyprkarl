export type SwitchGlyph = {
  glyph: string
  glyphOffset: [number, number]
}

export type SwitchMetrics = {
  thumbSize: number
  trackHeight: number
  trackLength: number
  thumbPadding: number
  borderWidth: number
  fontSize: number
  fontFamily: string
  glyphs: {
    on: SwitchGlyph
    off: SwitchGlyph
  }
}

// Back-compat aliases; old code referred to these as Normalized*.
export type NormalizedSwitchGlyph = SwitchGlyph
export type NormalizedSwitchMetrics = SwitchMetrics
