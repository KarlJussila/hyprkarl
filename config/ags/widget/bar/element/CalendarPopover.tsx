import { Accessor } from "ags";
import { Gtk } from "ags/gtk4";
import GLib from "gi://GLib?version=2.0";

type Props = {
    now: Accessor<GLib.DateTime>
}

export default function CalendarPopover({ now }: Props) {
    return (
        <popover hasArrow={false}>
            <box orientation={Gtk.Orientation.VERTICAL}>
                <label label={now(d => d.format("%B %Y")!)} />
                <Gtk.Calendar showHeading={false} canTarget={false} />
            </box>
        </popover>
    )
}