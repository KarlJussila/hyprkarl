import { Gtk } from "ags/gtk4";
import { createPoll } from "ags/time";
import GLib from "gi://GLib?version=2.0";
import Button from "./Button";
import CalendarPopover from "./CalendarPopover";

export default function Clock() {
    const now = createPoll(GLib.DateTime.new_now_local(), 1000, () => GLib.DateTime.new_now_local())
    const popover = <CalendarPopover now={now} /> as Gtk.Popover
    return (
        <Button
            popover={popover}
            execPrimary={() => popover.popup()}
        >
            <label label={now(d => d.format("%a %-I:%M %p")!)} />
        </Button>
    )
}