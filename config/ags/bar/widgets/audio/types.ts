import type { NormalizedSliderMetrics } from "../../primitives/sliderTypes.ts"

export type AudioTooltipConfig = {
  active?: string
  muted?: string
  unavailable?: string
}

export type NormalizedAudioTooltipConfig = {
  active: string
  muted: string
  unavailable: string
}

export type SliderMetrics = Partial<NormalizedSliderMetrics>
