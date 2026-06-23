export type WifiIcons = [string, string, string, string, string]

// Map an access-point signal strength (0–100) onto the five-step wifi glyph set.
export function selectWifiIcon(strength: number, wifiIcons: WifiIcons) {
  if (strength >= 80) return wifiIcons[4]
  if (strength >= 60) return wifiIcons[3]
  if (strength >= 40) return wifiIcons[2]
  if (strength >= 20) return wifiIcons[1]
  return wifiIcons[0]
}
