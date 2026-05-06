import { createState } from "ags"
import { Gdk, Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import GLib from "gi://GLib?version=2.0"
import { type NormalizedClockWidgetConfig } from "../../configuration"
import { type DropdownPlacement } from "../../layout/placement"
import AttachedDropdown from "../../overlays/dropdown/AttachedDropdown"
import Button from "../../primitives/Button"
import CalendarDropdownContent from "./CalendarDropdownContent"

let nextCalendarDropdownId = 1

function formatTime(time: GLib.DateTime, format: string) {
  return time.format(format) ?? ""
}

type Props = {
  placement: DropdownPlacement
  monitor: Gdk.Monitor
  config: NormalizedClockWidgetConfig
}

export default function ClockWidget({ placement, monitor, config }: Props) {
  const currentTime = createPoll(
    GLib.DateTime.new_now_local(),
    1000,
    () => GLib.DateTime.new_now_local(),
  )
  const [calendarOpen, setCalendarOpen] = createState(false)
  const [triggerButton, setTriggerButton] = createState<Gtk.Widget | null>(null)
  const calendarDropdownId = nextCalendarDropdownId++

  if (config.dropdown.enabled) {
    const mountedCalendarDropdown = (
      <AttachedDropdown
        name={`calendar-menu-${calendarDropdownId}`}
        placement={placement}
        monitor={monitor}
        trigger={triggerButton}
        open={calendarOpen}
        onRequestClose={() => setCalendarOpen(false)}
        align={config.dropdown.align}
        gap={config.dropdown.gap}
      >
        <CalendarDropdownContent currentTime={currentTime} />
      </AttachedDropdown>
    )

    void mountedCalendarDropdown
  }

  const horizontalClock = (
    <label label={currentTime((time) => formatTime(time, config.display.horizontal))} />
  )

  const verticalClock = (
    <box
      class="clock-display orientation-vertical"
      orientation={Gtk.Orientation.VERTICAL}
      spacing={0}
      hexpand={placement.isVertical}
      halign={Gtk.Align.CENTER}
    >
      <label class="clock-time" xalign={0.5} label={currentTime((time) => formatTime(time, config.display.vertical.top))} />
      <label class="clock-time" xalign={0.5} label={currentTime((time) => formatTime(time, config.display.vertical.middle))} />
      <label class="clock-meridiem" xalign={0.5} label={currentTime((time) => formatTime(time, config.display.vertical.bottom))} />
    </box>
  )

  return (
    <Button
      class={`clock-button orientation-${placement.orientation}`}
      hexpand={placement.isVertical}
      halign={placement.isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      $={config.dropdown.enabled
        ? (self) => {
            setTriggerButton(self)
            self.connect("destroy", () => {
              setTriggerButton(null)
            })
          }
        : undefined}
      execPrimary={config.dropdown.enabled
        ? () => setCalendarOpen(!calendarOpen())
        : undefined}
    >
      {placement.isVertical ? verticalClock : horizontalClock}
    </Button>
  )
}

