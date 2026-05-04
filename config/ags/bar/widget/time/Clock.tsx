import { createState } from "ags"
import { Gdk, Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import GLib from "gi://GLib?version=2.0"
import { type DropdownPlacement } from "../../barPlacement"
import Button from "../../button/Button"
import AttachedDropdown from "../../window/dropdown/AttachedDropdown"
import CalendarDropdownContent from "./CalendarDropdownContent"

let nextCalendarDropdownId = 1

type Props = {
  placement: DropdownPlacement
  monitor: Gdk.Monitor
}

export default function Clock({ placement, monitor }: Props) {
  const currentTime = createPoll(
    GLib.DateTime.new_now_local(),
    1000,
    () => GLib.DateTime.new_now_local(),
  )
  const [calendarOpen, setCalendarOpen] = createState(false)
  const [triggerButton, setTriggerButton] = createState<Gtk.Widget | null>(null)
  const calendarDropdownId = nextCalendarDropdownId++

  const mountedCalendarDropdown = (
    <AttachedDropdown
      name={`calendar-menu-${calendarDropdownId}`}
      placement={placement}
      monitor={monitor}
      trigger={triggerButton}
      open={calendarOpen}
      onRequestClose={() => setCalendarOpen(false)}
      align="center"
      gap={0}
    >
      <CalendarDropdownContent currentTime={currentTime} />
    </AttachedDropdown>
  )

  void mountedCalendarDropdown

  const horizontalClock = (
    <label label={currentTime((time) => time.format("%a %-I:%M %p")!)} />
  )

  const verticalClock = (
    <box
      class="clock-display orientation-vertical"
      orientation={Gtk.Orientation.VERTICAL}
      spacing={0}
      hexpand={placement.isVertical}
      halign={Gtk.Align.CENTER}
    >
      <label class="clock-time" xalign={0.5} label={currentTime((time) => time.format("%I")!)} />
      <label class="clock-time" xalign={0.5} label={currentTime((time) => time.format("%M")!)} />
      <label class="clock-meridiem" xalign={0.5} label={currentTime((time) => time.format("%p")!)} />
    </box>
  )

  return (
    <Button
      class={`clock-button orientation-${placement.orientation}`}
      hexpand={placement.isVertical}
      halign={placement.isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      $={(self) => {
        setTriggerButton(self)
        self.connect("destroy", () => {
          setTriggerButton(null)
        })
      }}
      execPrimary={() => setCalendarOpen(!calendarOpen())}
    >
      {placement.isVertical ? verticalClock : horizontalClock}
    </Button>
  )
}
