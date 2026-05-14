import { type Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import { type NormalizedSliderMetrics } from "../../configuration.ts"
import { type BarEdge } from "../../configuration.ts"
import Slider from "../../primitives/Slider.tsx"
import { formatAudioPercentage } from "./audioTooltip.ts"

type Props = {
  edge: BarEdge
  volume: Accessor<number>
  onChange: (next: number) => void
  metrics: NormalizedSliderMetrics
}

export default function AudioSliderDropdown({
  edge,
  volume,
  onChange,
  metrics,
}: Props) {
  const sliderOrientation = edge === "top" || edge === "bottom" ? "vertical" : "horizontal"
  const isVerticalSlider = sliderOrientation === "vertical"
  const percentFirst = edge === "bottom" || edge === "right"
  const percentageLabel = (
    <label
      class="widget-audio-slider-percent"
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
      label={volume(formatAudioPercentage)}
    />
  )
  const slider = (
    <Slider
      class="widget-audio-volume-slider"
      orientation={sliderOrientation}
      value={volume}
      onChange={onChange}
      metrics={metrics}
    />
  )

  return (
    <box
      class="widget-audio-slider-row"
      orientation={isVerticalSlider ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
      spacing={8}
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
    >
      {percentFirst ? percentageLabel : slider}
      {percentFirst ? slider : percentageLabel}
    </box>
  )
}
