import {
  childContext,
  normalizeObjectConfig,
  normalizeStringValue,
  type ValidationContext,
} from "../shared/normalize.ts"

export type BluetoothIcons = {
  enabled?: string
  disabled?: string
}

export type NormalizedBluetoothIcons = {
  enabled: string
  disabled: string
}

export function normalizeBluetoothIcons(
  ctx: ValidationContext,
  value: BluetoothIcons | undefined,
  defaults: NormalizedBluetoothIcons,
): NormalizedBluetoothIcons {
  const raw = normalizeObjectConfig(ctx, value) as BluetoothIcons | undefined
  return {
    enabled: normalizeStringValue(childContext(ctx, "enabled"), raw?.enabled, defaults.enabled),
    disabled: normalizeStringValue(childContext(ctx, "disabled"), raw?.disabled, defaults.disabled),
  }
}

export type BluetoothTooltipConfig = {
  off?: string
  on?: string
  connected?: string
}

export type NormalizedBluetoothTooltip = {
  off: string
  on: string
  connected: string
}

export function normalizeBluetoothTooltip(
  ctx: ValidationContext,
  value: BluetoothTooltipConfig | undefined,
  defaults: NormalizedBluetoothTooltip,
): NormalizedBluetoothTooltip {
  const raw = normalizeObjectConfig(ctx, value) as BluetoothTooltipConfig | undefined
  return {
    off: normalizeStringValue(childContext(ctx, "off"), raw?.off, defaults.off),
    on: normalizeStringValue(childContext(ctx, "on"), raw?.on, defaults.on),
    connected: normalizeStringValue(childContext(ctx, "connected"), raw?.connected, defaults.connected),
  }
}
