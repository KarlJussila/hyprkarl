import { Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import GLib from "gi://GLib?version=2.0"

function ordinal(n: number): string {
  const s = ["th", "st", "nd", "rd"]
  const v = n % 100
  return n + (s[(v - 20) % 10] || s[v] || s[0])
}

function formatDate(time: GLib.DateTime): string {
  const month = time.format("%B")!
  const year = time.format("%Y")!
  return `${month} ${ordinal(time.get_day_of_month())} ${year}`
}

type Props = {
  currentTime: Accessor<GLib.DateTime>
}

export default function CalendarDropdownContent({ currentTime }: Props) {
  return (
    <box class="calendar-dropdown" orientation={Gtk.Orientation.VERTICAL}>
      <label label={currentTime(formatDate)} />
      <Gtk.Calendar showHeading={false} canTarget={false} />
    </box>
  )
}