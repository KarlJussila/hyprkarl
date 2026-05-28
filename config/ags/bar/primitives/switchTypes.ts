export type NormalizedSwitchGlyph = {
  glyph: string
  glyphOffset: [number, number]
}

export type NormalizedSwitchMetrics = {
  thumbSize: number
  trackHeight: number
  trackLength: number
  thumbPadding: number
  borderWidth: number
  fontSize: number
  fontFamily: string
  glyphs: {
    on: NormalizedSwitchGlyph
    off: NormalizedSwitchGlyph
  }
}
