import { createComputed, createState } from "ags"
import { Gdk, Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import GLib from "gi://GLib?version=2.0"
import { type FlyoutPlacement } from "../../layout/placement.ts"
import FlyoutButton from "../shared/FlyoutButton.tsx"
import { createWidgetFlyoutName } from "../shared/instanceNames.ts"
import CalendarFlyoutContent from "./CalendarFlyoutContent"
import type { NormalizedFlyoutConfig } from "../../overlays/flyout/flyoutTypes.ts"

type Props = {
  id: string
  placement: FlyoutPlacement
  monitor: Gdk.Monitor
  format: string
  formatAlt: string
  formatVertical: string
  formatVerticalAlt: string
  flyout: NormalizedFlyoutConfig
}

export default function ClockWidget({ id, placement, monitor, format, formatAlt, formatVertical, formatVerticalAlt, flyout }: Props) {
  const currentTime = createPoll(
    GLib.DateTime.new_now_local(),
    1000,
    () => GLib.DateTime.new_now_local(),
  )
  const [useAlt, setUseAlt] = createState(false)

  const primaryFormat = placement.isVertical && formatVertical ? formatVertical : format
  const altFormat = placement.isVertical && formatVerticalAlt ? formatVerticalAlt : formatAlt
  const hasAlt = altFormat.length > 0

  const labelText = createComputed(() => {
    const fmt = hasAlt && useAlt() ? altFormat : primaryFormat
    return currentTime().format(fmt) ?? ""
  })

  return (
    <FlyoutButton
      widgetClass="widget-clock-button"
      placement={placement}
      monitor={monitor}
      flyoutName={createWidgetFlyoutName("calendar-menu", id, monitor.connector)}
      flyout={flyout}
      execSecondary={hasAlt ? () => setUseAlt(!useAlt()) : undefined}
      renderFlyoutContent={() => <CalendarFlyoutContent currentTime={currentTime} />}
    >
      <label
        class={`widget-clock-time widget-readout is-${placement.orientation}`}
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
        hexpand={placement.isVertical}
        justify={Gtk.Justification.CENTER}
        xalign={0.5}
        label={labelText}
      />
    </FlyoutButton>
  )
}
