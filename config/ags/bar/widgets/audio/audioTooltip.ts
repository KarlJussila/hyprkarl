import type { NormalizedAudioTooltipConfig } from "./types.ts"

function formatAudioPercentage(volume: number) {
  return `${Math.round(Math.max(0, volume) * 100)}%`
}

function renderAudioTooltipFormat(
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

export function formatAudioTooltip({
  muted,
  volume,
  device,
  formats,
}: {
  muted: boolean
  volume: number
  device?: string
  formats: NormalizedAudioTooltipConfig
}) {
  const replacements = {
    device: device?.trim() || undefined,
    percentage: formatAudioPercentage(volume),
  }

  return renderAudioTooltipFormat(
    muted ? formats.muted : formats.active,
    replacements,
  )
}

export function formatUnavailableAudioTooltip(formats: NormalizedAudioTooltipConfig) {
  return renderAudioTooltipFormat(formats.unavailable, {})
}

export { formatAudioPercentage }
