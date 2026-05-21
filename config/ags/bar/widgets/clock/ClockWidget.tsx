import { Gdk, Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import GLib from "gi://GLib?version=2.0"
import { type FlyoutPlacement } from "../../layout/placement.ts"
import FlyoutButton from "../shared/FlyoutButton.tsx"
import { createWidgetFlyoutName } from "../shared/instanceNames.ts"
import CalendarFlyoutContent from "./CalendarFlyoutContent"
import type { NormalizedFlyoutConfig } from "../../overlays/flyout/flyoutTypes.ts"
import type { NormalizedClockDisplayConfig } from "./types.ts"

function formatTime(time: GLib.DateTime, format: string) {
  return time.format(format) ?? ""
}

type Props = {
  id: string
  placement: FlyoutPlacement
  monitor: Gdk.Monitor
  display: NormalizedClockDisplayConfig
  flyout: NormalizedFlyoutConfig
}

export default function ClockWidget({ id, placement, monitor, display, flyout }: Props) {
  const currentTime = createPoll(
    GLib.DateTime.new_now_local(),
    1000,
    () => GLib.DateTime.new_now_local(),
  )

  const horizontalClock = (
    <label label={currentTime((time) => formatTime(time, display.horizontal))} />
  )

  const verticalClock = (
    <box
      class="widget-clock-display widget-icon-display is-vertical"
      orientation={Gtk.Orientation.VERTICAL}
      spacing={0}
      hexpand={placement.isVertical}
      halign={Gtk.Align.CENTER}
    >
      <label class="widget-clock-time widget-readout" xalign={0.5} label={currentTime((time) => formatTime(time, display.vertical.top))} />
      <label class="widget-clock-time widget-readout" xalign={0.5} label={currentTime((time) => formatTime(time, display.vertical.middle))} />
      <label class="widget-clock-meridiem widget-readout" xalign={0.5} label={currentTime((time) => formatTime(time, display.vertical.bottom))} />
    </box>
  )

  return (
    <FlyoutButton
      widgetClass="widget-clock-button"
      placement={placement}
      monitor={monitor}
      flyoutName={createWidgetFlyoutName("calendar-menu", id, monitor.connector)}
      flyout={flyout}
      renderFlyoutContent={() => <CalendarFlyoutContent currentTime={currentTime} />}
    >
      {placement.isVertical ? verticalClock : horizontalClock}
    </FlyoutButton>
  )
}
