export type FlyoutAlign = "start" | "center" | "end"

export type FlyoutConfig = {
  align?: FlyoutAlign
  gap?: number
}

export type NormalizedFlyoutConfig = {
  align: FlyoutAlign
  gap: number
}
