import type { NormalizedBatteryTooltipConfig } from "./types.ts"
import { formatBatteryPercentage } from "./batteryStateShared.ts"

function formatPower(powerWatts: number) {
  return `${powerWatts.toFixed(1)}W`
}

function formatSeconds(seconds: number) {
  if (!Number.isFinite(seconds) || seconds <= 0) {
    return undefined
  }

  const totalMinutes = Math.round(seconds / 60)
  const hours = Math.floor(totalMinutes / 60)
  const minutes = totalMinutes % 60
  return `${hours}:${String(minutes).padStart(2, "0")}`
}

export function formatBatteryTooltip({
  percentage,
  charging,
  energyRate,
  timeToEmpty,
  timeToFull,
  formats,
}: {
  percentage: number
  charging: boolean
  energyRate: number
  timeToEmpty: number
  timeToFull: number
  formats: NormalizedBatteryTooltipConfig
}) {
  const percent = formatBatteryPercentage(percentage)
  const power = Math.abs(energyRate)
  const duration = formatSeconds(charging ? timeToFull : timeToEmpty)

  if (power > 0) {
    return renderBatteryTooltipFormat(
      charging ? formats.charging : formats.discharging,
      {
        power: formatPower(power),
        time: duration,
        percentage: percent,
      },
    )
  }

  if (charging) {
    return renderBatteryTooltipFormat(formats.plugged, {
      percentage: percent,
    })
  }

  return renderBatteryTooltipFormat(formats.fallback, {
    percentage: percent,
  })
}

function renderBatteryTooltipFormat(
  format: string,
  replacements: Record<string, string | undefined>,
) {
  const rendered = Object.entries(replacements).reduce(
    (result, [token, value]) => result.replaceAll(`{${token}}`, value ?? ""),
    format,
  )

  return rendered
    .split("\n")
    .map((line) => line.replace(/\s+/g, " ").trim())
    .join("\n")
    .trim()
}
