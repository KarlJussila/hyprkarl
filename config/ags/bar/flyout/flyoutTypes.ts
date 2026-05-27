export type FlyoutAlign = "start" | "center" | "end"

export type FlyoutConfig = {
  enabled?: boolean
  align?: FlyoutAlign
  gap?: number
}

export type NormalizedFlyoutConfig = {
  enabled: boolean
  align: FlyoutAlign
  gap: number
}
