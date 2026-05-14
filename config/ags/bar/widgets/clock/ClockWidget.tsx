import { Gdk, Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import GLib from "gi://GLib?version=2.0"
import { type NormalizedClockWidgetConfig } from "../../configuration.ts"
import { type FlyoutPlacement } from "../../layout/placement.ts"
import FlyoutButton from "../shared/FlyoutButton.tsx"
import { createWidgetFlyoutName } from "../shared/instanceNames.ts"
import CalendarFlyoutContent from "./CalendarFlyoutContent"

function formatTime(time: GLib.DateTime, format: string) {
  return time.format(format) ?? ""
}

type Props = {
  id: string
  placement: FlyoutPlacement
  monitor: Gdk.Monitor
  config: NormalizedClockWidgetConfig
}

export default function ClockWidget({ id, placement, monitor, config }: Props) {
  const currentTime = createPoll(
    GLib.DateTime.new_now_local(),
    1000,
    () => GLib.DateTime.new_now_local(),
  )

  const horizontalClock = (
    <label label={currentTime((time) => formatTime(time, config.display.horizontal))} />
  )

  const verticalClock = (
    <box
      class="widget-clock-display orientation-vertical is-vertical"
      orientation={Gtk.Orientation.VERTICAL}
      spacing={0}
      hexpand={placement.isVertical}
      halign={Gtk.Align.CENTER}
    >
      <label class="widget-clock-time" xalign={0.5} label={currentTime((time) => formatTime(time, config.display.vertical.top))} />
      <label class="widget-clock-time" xalign={0.5} label={currentTime((time) => formatTime(time, config.display.vertical.middle))} />
      <label class="widget-clock-meridiem" xalign={0.5} label={currentTime((time) => formatTime(time, config.display.vertical.bottom))} />
    </box>
  )

  return (
    <FlyoutButton
      buttonClass={`widget-clock-button orientation-${placement.orientation} is-${placement.orientation}`}
      hexpand={placement.isVertical}
      halign={placement.isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      placement={placement}
      monitor={monitor}
      flyoutName={createWidgetFlyoutName("calendar-menu", id, monitor.connector)}
      flyout={config.flyout}
      renderFlyoutContent={() => <CalendarFlyoutContent currentTime={currentTime} />}
    >
      {placement.isVertical ? verticalClock : horizontalClock}
    </FlyoutButton>
  )
}
