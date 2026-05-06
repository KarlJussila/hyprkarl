import { Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import GLib from "gi://GLib?version=2.0"

function ordinal(n: number): string {
  const suffixes = ["th", "st", "nd", "rd"]
  const value = n % 100
  return n + (suffixes[(value - 20) % 10] || suffixes[value] || suffixes[0])
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
    <box orientation={Gtk.Orientation.VERTICAL}>
      <label label={currentTime(formatDate)} />
      <Gtk.Calendar showHeading={false} canTarget={false} />
    </box>
  )
}

