import { createBinding, createComputed, createState } from "ags"
import { execAsync } from "ags/process"
import { Gdk, Gtk } from "ags/gtk4"
import AstalWp from "gi://AstalWp"
import { type NormalizedAudioWidgetConfig } from "../../configuration.ts"
import { type DropdownPlacement } from "../../layout/placement.ts"
import DropdownButton from "../shared/DropdownButton.tsx"
import { createWidgetDropdownName } from "../shared/instanceNames.ts"
import AudioIndicator from "./AudioIndicator.tsx"
import AudioSliderDropdown from "./AudioSliderDropdown.tsx"
import {
  formatAudioPercentage,
  formatAudioTooltip,
  formatUnavailableAudioTooltip,
} from "./audioTooltip.ts"

type Props = {
  id: string
  placement: DropdownPlacement
  monitor: Gdk.Monitor
  config: NormalizedAudioWidgetConfig
}

function readString(value: unknown) {
  return typeof value === "string" ? value.trim() : ""
}

export default function AudioWidget({ id, placement, monitor, config }: Props) {
  const speaker = AstalWp.get_default()?.defaultSpeaker ?? null
  const launchAudio = () => execAsync(config.command).catch(() => {})
  const [unavailableVolume] = createState(0)
  const [unavailableMuted] = createState(true)

  if (!speaker) {
    return (
      <DropdownButton
        buttonClass={`widget-audio-button orientation-${placement.orientation} is-${placement.orientation}`}
        hexpand={placement.isVertical}
        halign={placement.isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
        placement={placement}
        monitor={monitor}
        dropdownName={createWidgetDropdownName("audio-menu", id, monitor.connector)}
        dropdown={config.dropdown}
        tooltipText={formatUnavailableAudioTooltip(config.tooltip)}
        execPrimary={launchAudio}
        execSecondary={launchAudio}
        renderDropdownContent={() => <label label="Audio unavailable" />}
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
            orientation={placement.orientation}
            volume={unavailableVolume}
            muted={unavailableMuted}
          />
        </box>
      </DropdownButton>
    )
  }

  const volume = createBinding(speaker, "volume")
  const muted = createBinding(speaker, "mute")
  const description = createBinding(speaker, "description")
  const tooltipText = createComputed(() => formatAudioTooltip({
    muted: muted(),
    volume: volume(),
    device: readString(description()),
    formats: config.tooltip,
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
        orientation={placement.orientation}
        volume={volume}
        muted={muted}
      />
      {config.showPercentage && (
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
    <DropdownButton
      buttonClass={`widget-audio-button orientation-${placement.orientation} is-${placement.orientation}`}
      hexpand={placement.isVertical}
      halign={placement.isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      placement={placement}
      monitor={monitor}
      dropdownName={createWidgetDropdownName("audio-menu", id, monitor.connector)}
      dropdown={config.dropdown}
      tooltipText={tooltipText}
      execPrimary={launchAudio}
      execSecondary={launchAudio}
      renderDropdownContent={() => (
        <AudioSliderDropdown
          volume={volume}
          onChange={(next) => speaker.set_volume(next)}
          metrics={config.slider}
        />
      )}
    >
      {audioContent}
    </DropdownButton>
  )
}
