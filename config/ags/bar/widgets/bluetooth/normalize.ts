import {
  childContext,
  normalizeBoolean,
  normalizeObjectConfig,
  normalizeStringValue,
  type ValidationContext,
} from "../shared/normalize.ts"

export type BluetoothIconsConfig = {
  enabled?: string
  disabled?: string
}

export type NormalizedBluetoothIcons = {
  enabled: string
  disabled: string
}

export function normalizeBluetoothIcons(
  ctx: ValidationContext,
  config: BluetoothIconsConfig | undefined,
  defaults: NormalizedBluetoothIcons,
): NormalizedBluetoothIcons {
  const raw = normalizeObjectConfig(ctx, config) as BluetoothIconsConfig | undefined
  return {
    enabled: normalizeStringValue(childContext(ctx, "enabled"), raw?.enabled, defaults.enabled),
    disabled: normalizeStringValue(childContext(ctx, "disabled"), raw?.disabled, defaults.disabled),
  }
}

export type BluetoothTooltipConfig = {
  enabled?: boolean
  off?: string
  on?: string
  connected?: string
}

export type NormalizedBluetoothTooltip = {
  enabled: boolean
  off: string
  on: string
  connected: string
}

export function normalizeBluetoothTooltipConfig(
  ctx: ValidationContext,
  config: BluetoothTooltipConfig | undefined,
  defaults: NormalizedBluetoothTooltip,
): NormalizedBluetoothTooltip {
  const raw = normalizeObjectConfig(ctx, config) as BluetoothTooltipConfig | undefined
  return {
    enabled: normalizeBoolean(childContext(ctx, "enabled"), raw?.enabled, defaults.enabled),
    off: normalizeStringValue(childContext(ctx, "off"), raw?.off, defaults.off),
    on: normalizeStringValue(childContext(ctx, "on"), raw?.on, defaults.on),
    connected: normalizeStringValue(childContext(ctx, "connected"), raw?.connected, defaults.connected),
  }
}
