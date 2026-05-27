import { Gdk, Gtk } from "ags/gtk4"
import type { NormalizedSliderMetrics } from "../../primitives/sliderTypes.ts"
import { type FlyoutPlacement } from "../../layout/placement.ts"
import Button from "../../primitives/Button.tsx"
import type { NormalizedFlyoutConfig } from "../../flyout/flyoutTypes.ts"
import { createFlyoutCommands } from "../../flyout/createFlyoutCommands.tsx"
import AudioIndicator from "./AudioIndicator.tsx"
import AudioSliderFlyout from "./AudioSliderFlyout.tsx"
import { formatReadoutPercent } from "../shared/formatters.ts"
import { createAudioState } from "./audioState.ts"
import type { NormalizedAudioTooltipConfig } from "./types.ts"
import type { NormalizedClickCommandsConfig } from "../shared/normalize.ts"

type Props = {
  id: string
  placement: FlyoutPlacement
  monitor: Gdk.Monitor
  showPercentage: boolean
  commands: NormalizedClickCommandsConfig
  flyout: NormalizedFlyoutConfig
  tooltip: NormalizedAudioTooltipConfig
  slider: NormalizedSliderMetrics
}

export default function AudioWidget({
  id,
  placement,
  monitor,
  showPercentage,
  commands,
  flyout,
  tooltip,
  slider,
}: Props) {
  const audioState = createAudioState(tooltip)

  const { execPrimary, execSecondary, execMiddle, triggerSetup } = createFlyoutCommands({
    flyout,
    placement,
    monitor,
    id,
    label: "audio-menu",
    commands,
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
  })

  return (
    <Button
      class={`widget-audio-button widget-glyph-button is-${placement.orientation}`}
      orientation={placement.orientation}
      tooltipText={audioState.tooltipText}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execMiddle={execMiddle}
      $={triggerSetup}
    >
      <box
        class={`widget-audio-display widget-icon-display is-${placement.orientation}`}
        orientation={placement.isVertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
        spacing={0}
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
      >
        <AudioIndicator volume={audioState.volume} muted={audioState.muted} />
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
