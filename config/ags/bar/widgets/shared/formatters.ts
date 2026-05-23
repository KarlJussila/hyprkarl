export function formatReadoutPercent(fraction: number): string {
  const pct = Math.round(Math.max(0, fraction) * 100)
  return pct >= 100 ? "MAX" : `${pct}%`
}
