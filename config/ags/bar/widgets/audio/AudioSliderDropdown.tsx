import { type Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import { type NormalizedSliderMetrics } from "../../configuration.ts"
import Slider from "../../primitives/Slider.tsx"
import { formatAudioPercentage } from "./audioTooltip.ts"

type Props = {
  volume: Accessor<number>
  onChange: (next: number) => void
  metrics: NormalizedSliderMetrics
}

export default function AudioSliderDropdown({
  volume,
  onChange,
  metrics,
}: Props) {
  return (
    <box
      class="widget-audio-slider-row"
      spacing={8}
      valign={Gtk.Align.CENTER}
    >
      <Slider
        class="widget-audio-volume-slider"
        orientation="horizontal"
        value={volume}
        onChange={onChange}
        metrics={metrics}
      />
      <label
        class="widget-audio-slider-percent"
        valign={Gtk.Align.CENTER}
        label={volume(formatAudioPercentage)}
      />
    </box>
  )
}
