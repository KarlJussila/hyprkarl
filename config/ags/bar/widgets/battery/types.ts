export type BatteryIndicatorMetrics = {
  width?: number
  height?: number
  borderWidth?: number
  terminalWidth?: number
  terminalHeight?: number
  chargingGlyph?: string
  chargingGlyphFontSize?: number
  chargingGlyphFontFamily?: string
}

export type NormalizedBatteryIndicatorMetrics = {
  width: number
  height: number
  borderWidth: number
  terminalWidth: number
  terminalHeight: number
  chargingGlyph: string
  chargingGlyphFontSize: number
  chargingGlyphFontFamily: string
}

export type BatteryTooltipConfig = {
  charging?: string
  discharging?: string
  plugged?: string
  fallback?: string
}

export type NormalizedBatteryTooltipConfig = {
  charging: string
  discharging: string
  plugged: string
  fallback: string
}
