import type { NormalizedSliderMetrics } from "../../primitives/sliderTypes.ts"

export type AudioTooltipConfig = {
  enabled?: boolean
  active?: string
  muted?: string
  unavailable?: string
}

export type NormalizedAudioTooltipConfig = {
  enabled: boolean
  active: string
  muted: string
  unavailable: string
}

export type SliderMetrics = Partial<NormalizedSliderMetrics>
