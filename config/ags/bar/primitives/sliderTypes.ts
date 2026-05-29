export type SliderMetrics = {
  trackLength: number
  trackThickness: number
  trackRadius: number
  fillRadius: number
  borderWidth: number
  thumbWidth: number
  thumbHeight: number
  thumbRadius: number
  thumbVisible: boolean
}

// Back-compat alias; old code referred to this as Normalized*.
export type NormalizedSliderMetrics = SliderMetrics
