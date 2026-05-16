import { createBinding, createComputed, createState } from "ags"
import { execAsync } from "ags/process"
import { Gdk, Gtk } from "ags/gtk4"
import AstalWp from "gi://AstalWp"
import type { NormalizedSliderMetrics } from "../../primitives/sliderTypes.ts"
import { type FlyoutPlacement } from "../../layout/placement.ts"
import FlyoutButton from "../shared/FlyoutButton.tsx"
import { createWidgetFlyoutName } from "../shared/instanceNames.ts"
import AudioIndicator from "./AudioIndicator.tsx"
import AudioSliderFlyout from "./AudioSliderFlyout.tsx"
import type { NormalizedFlyoutConfig } from "../shared/flyoutTypes.ts"
import {
  formatAudioPercentage,
  formatAudioTooltip,
  formatUnavailableAudioTooltip,
} from "./audioTooltip.ts"
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

function readString(value: unknown) {
  return typeof value === "string" ? value.trim() : ""
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
  const speaker = AstalWp.get_default()?.defaultSpeaker ?? null
  const launchAudio = () => execAsync(command).catch(() => {})
  const [unavailableVolume] = createState(0)
  const [unavailableMuted] = createState(true)

  if (!speaker) {
    return (
      <FlyoutButton
        buttonClass={`widget-audio-button orientation-${placement.orientation} is-${placement.orientation}`}
        hexpand={placement.isVertical}
        halign={placement.isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
        placement={placement}
        monitor={monitor}
        flyoutName={createWidgetFlyoutName("audio-menu", id, monitor.connector)}
        flyout={flyout}
        tooltipText={formatUnavailableAudioTooltip(tooltip)}
        execPrimary={launchAudio}
        execSecondary={launchAudio}
        renderFlyoutContent={() => <label label="Audio unavailable" />}
      >
        <box
          class={`widget-audio-display orientation-${placement.orientation} is-${placement.orientation}`}
          orientation={placement.isVertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
          spacing={0}
          hexpand={placement.isVertical}
          halign={Gtk.Align.CENTER}
          valign={Gtk.Align.CENTER}
        >
          <AudioIndicator
            orientation="horizontal"
            volume={unavailableVolume}
            muted={unavailableMuted}
          />
        </box>
      </FlyoutButton>
    )
  }

  const volume = createBinding(speaker, "volume")
  const muted = createBinding(speaker, "mute")
  const description = createBinding(speaker, "description")
  const tooltipText = createComputed(() => formatAudioTooltip({
    muted: muted(),
    volume: volume(),
    device: readString(description()),
    formats: tooltip,
  }))

  const audioContent = (
    <box
      class={`widget-audio-display orientation-${placement.orientation} is-${placement.orientation}`}
      orientation={placement.isVertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
      spacing={0}
      hexpand={placement.isVertical}
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
    >
      <AudioIndicator
        orientation="horizontal"
        volume={volume}
        muted={muted}
      />
      {showPercentage && (
        <label
          class="widget-audio-percent"
          xalign={0.5}
          valign={Gtk.Align.CENTER}
          label={volume(formatAudioPercentage)}
        />
      )}
    </box>
  )

  return (
    <FlyoutButton
      buttonClass={`widget-audio-button orientation-${placement.orientation} is-${placement.orientation}`}
      hexpand={placement.isVertical}
      halign={placement.isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      placement={placement}
      monitor={monitor}
      flyoutName={createWidgetFlyoutName("audio-menu", id, monitor.connector)}
      flyout={flyout}
      tooltipText={tooltipText}
      execPrimary={launchAudio}
      execSecondary={launchAudio}
      renderFlyoutContent={() => (
        <AudioSliderFlyout
          edge={placement.edge}
          volume={volume}
          onChange={(next) => speaker.set_volume(next)}
          metrics={slider}
        />
      )}
    >
      {audioContent}
    </FlyoutButton>
  )
}
