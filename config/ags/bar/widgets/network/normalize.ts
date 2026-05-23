import {
  childContext,
  fail,
  normalizeObjectConfig,
  normalizeStringValue,
  type ValidationContext,
} from "../shared/normalize.ts"

export type NetworkIcons = {
  disconnected?: string
  ethernet?: string
  wifi?: [string, string, string, string, string]
}

export type NormalizedNetworkIcons = {
  disconnected: string
  ethernet: string
  wifi: [string, string, string, string, string]
}

export function normalizeNetworkIcons(
  ctx: ValidationContext,
  value: NetworkIcons | undefined,
  defaults: NormalizedNetworkIcons,
): NormalizedNetworkIcons {
  const raw = normalizeObjectConfig(ctx, value) as NetworkIcons | undefined

  let wifi = defaults.wifi as [string, string, string, string, string]
  if (raw?.wifi !== undefined) {
    if (!Array.isArray(raw.wifi) || raw.wifi.length !== 5 || !raw.wifi.every((s: unknown) => typeof s === "string")) {
      fail(childContext(ctx, "wifi"), "must be an array of exactly 5 strings")
    }
    wifi = raw.wifi as [string, string, string, string, string]
  }

  return {
    disconnected: normalizeStringValue(childContext(ctx, "disconnected"), raw?.disconnected, defaults.disconnected),
    ethernet: normalizeStringValue(childContext(ctx, "ethernet"), raw?.ethernet, defaults.ethernet),
    wifi,
  }
}

export type NetworkTooltipConfig = {
  disconnected?: string
  ethernet?: string
  wifi?: string
  wifiNoFreq?: string
  wifiNoSsid?: string
}

export type NormalizedNetworkTooltip = {
  disconnected: string
  ethernet: string
  wifi: string
  wifiNoFreq: string
  wifiNoSsid: string
}

export function normalizeNetworkTooltip(
  ctx: ValidationContext,
  value: NetworkTooltipConfig | undefined,
  defaults: NormalizedNetworkTooltip,
): NormalizedNetworkTooltip {
  const raw = normalizeObjectConfig(ctx, value) as NetworkTooltipConfig | undefined
  return {
    disconnected: normalizeStringValue(childContext(ctx, "disconnected"), raw?.disconnected, defaults.disconnected),
    ethernet: normalizeStringValue(childContext(ctx, "ethernet"), raw?.ethernet, defaults.ethernet),
    wifi: normalizeStringValue(childContext(ctx, "wifi"), raw?.wifi, defaults.wifi),
    wifiNoFreq: normalizeStringValue(childContext(ctx, "wifiNoFreq"), raw?.wifiNoFreq, defaults.wifiNoFreq),
    wifiNoSsid: normalizeStringValue(childContext(ctx, "wifiNoSsid"), raw?.wifiNoSsid, defaults.wifiNoSsid),
  }
}
