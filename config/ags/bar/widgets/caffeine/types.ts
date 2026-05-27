import type { NormalizedSwitchMetrics } from "../../primitives/switchTypes.ts"

export type SwitchMetrics = Partial<NormalizedSwitchMetrics>

export type CaffeineTooltipConfig = {
  enabled?: boolean
  active?: string
  inactive?: string
}

export type NormalizedCaffeineTooltip = {
  enabled: boolean
  active: string
  inactive: string
}
