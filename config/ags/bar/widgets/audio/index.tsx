import { Gtk } from "ags/gtk4"
import type { SliderMetrics } from "../../primitives/sliderTypes.ts"
import Button from "../../primitives/Button.tsx"
import AudioIndicator, { type AudioIndicatorMetrics } from "./Indicator.tsx"
import AudioSliderFlyout from "./SliderFlyout.tsx"
import { formatReadoutPercent } from "../shared/formatters.ts"
import { useWidgetCommands } from "../shared/useWidgetCommands.ts"
import { createAudioState, type AudioTooltipTemplates } from "./state.ts"
import { mergeConfig, defaultFlyout, type WidgetClicks, type WidgetFlyout, type WidgetProps } from "../shared/types.ts"

export type AudioConfig = {
  showPercentage?: boolean
  commands?: WidgetClicks
  flyout?: WidgetFlyout
  tooltip?: Partial<AudioTooltipTemplates>
  indicator?: Partial<AudioIndicatorMetrics>
  slider?: Partial<SliderMetrics>
}

type AudioDefaults = {
  showPercentage: boolean
  commands: WidgetClicks
  flyout: WidgetFlyout
  tooltip: AudioTooltipTemplates
  indicator: AudioIndicatorMetrics
  slider: SliderMetrics
}

export const defaults: AudioDefaults = {
  showPercentage: true,
  commands: { secondary: "hk-launch-audio" },
  flyout: defaultFlyout,
  tooltip: {
    active: "{device} {percentage}",
    muted: "Muted {device}",
    unavailable: "Audio unavailable",
  },
  indicator: {
    height: 14,
    lineWidth: 1.4,
  },
  slider: {
    trackLength: 100,
    trackThickness: 6,
    trackRadius: 2,
    fillRadius: 2,
    borderWidth: 1,
    thumbWidth: 10,
    thumbHeight: 10,
    thumbRadius: 5,
    thumbVisible: true,
  },
}

export default function AudioWidget({ id, config, placement, monitor }: WidgetProps<AudioConfig>) {
  const cfg = mergeConfig(defaults, config)
  const { showPercentage, commands, flyout, tooltip, indicator, slider } = cfg
  const audioState = createAudioState(tooltip)

  const { execPrimary, execSecondary, execTertiary, triggerSetup } = useWidgetCommands({
    commands,
    flyout: {
      config: flyout,
      placement,
      monitor,
      id,
      label: "audio-menu",
      renderContent: () => audioState.isAvailable
        ? (
            <AudioSliderFlyout
              edge={placement.edge}
              volume={audioState.volume}
              onChange={audioState.setVolume}
              metrics={slider}
            />
          )
        : <label label="Audio unavailable" />,
    },
  })

  return (
    <Button
      class={`widget-audio-button widget-glyph-button is-${placement.orientation}`}
      orientation={placement.orientation}
      tooltipText={audioState.tooltipText}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execTertiary={execTertiary}
      $={triggerSetup}
    >
      <box
        class={`widget-audio-display widget-icon-display is-${placement.orientation}`}
        orientation={placement.isVertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
        spacing={0}
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
      >
        <AudioIndicator volume={audioState.volume} muted={audioState.muted} metrics={indicator} />
        {showPercentage && (
          <label
            class="widget-audio-percent widget-readout widget-readout-percent"
            xalign={0.5}
            valign={Gtk.Align.CENTER}
            widthChars={3}
            label={audioState.volume(formatReadoutPercent)}
          />
        )}
      </box>
    </Button>
  )
}
