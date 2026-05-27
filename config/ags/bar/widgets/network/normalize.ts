import {
  childContext,
  fail,
  type FieldNormalizer,
} from "../shared/normalize.ts"

type WifiIcons = [string, string, string, string, string]

export const normalizeWifiIcons: FieldNormalizer<WifiIcons, WifiIcons> = (ctx, value, fallback) => {
  if (value === undefined) return fallback
  if (!Array.isArray(value) || value.length !== 5 || !value.every((s) => typeof s === "string")) {
    fail(childContext(ctx, ""), "must be an array of exactly 5 strings")
  }
  return value as WifiIcons
}
