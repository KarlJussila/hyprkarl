import { createBinding, createComputed, createState, type Accessor } from "ags"
import AstalWp from "gi://AstalWp"
import { readString } from "../shared/read.ts"
import {
  formatAudioTooltip,
  formatUnavailableAudioTooltip,
} from "./audioTooltip.ts"
import type { NormalizedAudioTooltipConfig } from "./types.ts"

export type AudioState = {
  volume: Accessor<number>
  muted: Accessor<boolean>
  tooltipText: Accessor<string>
  isAvailable: boolean
  setVolume: (v: number) => void
}

export function createAudioState(formats: NormalizedAudioTooltipConfig): AudioState {
  const speaker = AstalWp.get_default()?.defaultSpeaker ?? null

  if (!speaker) {
    const [volume] = createState(0)
    const [muted] = createState(true)
    const unavailableTooltip = formatUnavailableAudioTooltip(formats)
    return {
      volume,
      muted,
      tooltipText: createComputed(() => unavailableTooltip),
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
    tooltipText: createComputed(() => formatAudioTooltip({
      muted: muted(),
      volume: volume(),
      device: readString(description()),
      formats,
    })),
    isAvailable: true,
    setVolume: (v) => { if (volume() !== v) speaker.set_volume(v) },
  }
}
