import { execAsync } from "ags/process"
import { Gdk, Gtk } from "ags/gtk4"
import type { NormalizedSliderMetrics } from "../../primitives/sliderTypes.ts"
import { type FlyoutPlacement } from "../../layout/placement.ts"
import FlyoutButton from "../shared/FlyoutButton.tsx"
import { createWidgetFlyoutName } from "../shared/instanceNames.ts"
import type { NormalizedFlyoutConfig } from "../../overlays/flyout/flyoutTypes.ts"
import AudioIndicator from "./AudioIndicator.tsx"
import AudioSliderFlyout from "./AudioSliderFlyout.tsx"
import { formatReadoutPercent } from "../shared/formatters.ts"
import { createAudioState } from "./audioState.ts"
import type { NormalizedAudioTooltipConfig } from "./types.ts"

type Props = {
  id: string
  placement: FlyoutPlacement
  monitor: Gdk.Monitor
  showPercentage: boolean
  command: string
  flyout: NormalizedFlyoutConfig
  tooltip: NormalizedAudioTooltipConfig
  slider: NormalizedSliderMetrics
}

export default function AudioWidget({
  id,
  placement,
  monitor,
  showPercentage,
  command,
  flyout,
  tooltip,
  slider,
}: Props) {
  const audioState = createAudioState(tooltip)
  const launchAudio = () => execAsync(command).catch(() => {})
  const flyoutName = createWidgetFlyoutName("audio-menu", id, monitor.connector)

  return (
    <FlyoutButton
      widgetClass="widget-audio-button widget-glyph-button"
      placement={placement}
      monitor={monitor}
      flyoutName={flyoutName}
      flyout={flyout}
      tooltipText={audioState.tooltipText}
      execPrimary={launchAudio}
      execSecondary={launchAudio}
      renderFlyoutContent={() => audioState.isAvailable
        ? (
            <AudioSliderFlyout
              edge={placement.edge}
              volume={audioState.volume}
              onChange={audioState.setVolume}
              metrics={slider}
            />
          )
        : <label label="Audio unavailable" />}
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
    </FlyoutButton>
  )
}
