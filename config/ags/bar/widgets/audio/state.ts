import { createBinding, createComputed, createState, type Accessor } from "ags"
import AstalWp from "gi://AstalWp"
import {
  formatAudioTooltip,
  formatUnavailableAudioTooltip,
} from "./tooltip.ts"

// All three templates are tried in their respective state; set any to "" to
// suppress that tooltip. Set all three to "" to disable the tooltip entirely.
export type AudioTooltipTemplates = {
  active: string
  muted: string
  unavailable: string
}

export type AudioState = {
  volume: Accessor<number>
  muted: Accessor<boolean>
  tooltipText: Accessor<string> | undefined
  isAvailable: boolean
  setVolume: (v: number) => void
}

function hasAnyTooltipTemplate(formats: AudioTooltipTemplates): boolean {
  return Boolean(formats.active || formats.muted || formats.unavailable)
}

function readDescription(value: unknown): string {
  return typeof value === "string" ? value.trim() : ""
}

export function createAudioState(formats: AudioTooltipTemplates): AudioState {
  const speaker = AstalWp.get_default()?.defaultSpeaker ?? null
  const tooltipEnabled = hasAnyTooltipTemplate(formats)

  if (!speaker) {
    const [volume] = createState(0)
    const [muted] = createState(true)
    const unavailableTooltip = tooltipEnabled ? formatUnavailableAudioTooltip(formats) : undefined
    return {
      volume,
      muted,
      tooltipText: unavailableTooltip ? createComputed(() => unavailableTooltip) : undefined,
      isAvailable: false,
      setVolume: () => {},
    }
  }

  const volume = createBinding(speaker, "volume")
  const muted = createBinding(speaker, "mute")
  const description = createBinding(speaker, "description")

  return {
    volume,
    muted,
    tooltipText: tooltipEnabled
      ? createComputed(() => formatAudioTooltip({
          muted: muted(),
          volume: volume(),
          device: readDescription(description()),
          formats,
        }))
      : undefined,
    isAvailable: true,
    setVolume: (v) => { if (volume() !== v) speaker.set_volume(v) },
  }
}
