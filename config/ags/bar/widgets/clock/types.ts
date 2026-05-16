export type ClockDisplayConfig = {
  horizontal?: string
  vertical?: {
    top?: string
    middle?: string
    bottom?: string
  }
}

export type NormalizedClockDisplayConfig = {
  horizontal: string
  vertical: {
    top: string
    middle: string
    bottom: string
  }
}
