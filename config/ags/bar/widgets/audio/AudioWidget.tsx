import { Gtk } from "ags/gtk4"
import type { NormalizedSliderMetrics } from "../../primitives/sliderTypes.ts"
import Button from "../../primitives/Button.tsx"
import type { NormalizedFlyoutConfig } from "../../flyout/flyoutTypes.ts"
import AudioIndicator, { type AudioIndicatorMetrics } from "./AudioIndicator.tsx"
import AudioSliderFlyout from "./AudioSliderFlyout.tsx"
import { formatReadoutPercent } from "../shared/formatters.ts"
import { useWidgetCommands } from "../shared/useWidgetCommands.ts"
import { createAudioState, type AudioTooltipTemplates } from "./audioState.ts"
import type { WidgetRenderArgs } from "../shared/widgetSpec.tsx"
import type { NormalizedClickCommandsConfig } from "../shared/normalize.ts"

type Config = {
  showPercentage: boolean
  commands: NormalizedClickCommandsConfig
  flyout: NormalizedFlyoutConfig
  tooltip: AudioTooltipTemplates
  indicator: AudioIndicatorMetrics
  slider: NormalizedSliderMetrics
}

export default function AudioWidget({ id, config, placement, monitor }: WidgetRenderArgs<Config>) {
  const { showPercentage, commands, flyout, tooltip, indicator, slider } = config
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
