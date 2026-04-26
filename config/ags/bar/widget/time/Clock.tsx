import { createState } from "ags"
import { Gdk, Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import GLib from "gi://GLib?version=2.0"
import Button from "../../button/Button"
import AttachedDropdown from "../../window/dropdown/AttachedDropdown"
import CalendarDropdownContent from "./CalendarDropdownContent"

let nextCalendarDropdownId = 1

type Props = {
  monitor: Gdk.Monitor
}

export default function Clock({ monitor }: Props) {
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

  return (
    <Button
      $={(self) => {
        setTriggerButton(self)
        self.connect("destroy", () => {
          setTriggerButton(null)
        })
      }}
      execPrimary={() => setCalendarOpen(!calendarOpen())}
    >
      <label label={currentTime((time) => time.format("%a %-I:%M %p")!)} />
    </Button>
  )
}
