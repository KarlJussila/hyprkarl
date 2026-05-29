import { substituteTokens } from "../shared/template.ts"
import type { AudioTooltipTemplates } from "./state.ts"

function formatAudioPercentage(volume: number) {
  return `${Math.round(Math.max(0, volume) * 100)}%`
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
  formats: AudioTooltipTemplates
}) {
  const replacements = {
    device: device?.trim() || undefined,
    percentage: formatAudioPercentage(volume),
  }

  return substituteTokens(
    muted ? formats.muted : formats.active,
    replacements,
  )
}

export function formatUnavailableAudioTooltip(formats: AudioTooltipTemplates) {
  return substituteTokens(formats.unavailable, {})
}

export { formatAudioPercentage }
