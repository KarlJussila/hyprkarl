import { createComputed, createEffect, createState, onCleanup } from "ags"
import { Gdk, Gtk } from "ags/gtk4"
import { timeout, type Timer } from "ags/time"
import GLib from "gi://GLib?version=2.0"
import { type FlyoutPlacement } from "../../layout/placement.ts"
import FlyoutButton from "../shared/FlyoutButton.tsx"
import CalendarFlyoutContent from "./CalendarFlyoutContent"
import type { NormalizedFlyoutConfig } from "../../overlays/flyout/flyoutTypes.ts"
import type { NormalizedFormatConfig } from "../shared/normalize.ts"

type Props = {
  id: string
  placement: FlyoutPlacement
  monitor: Gdk.Monitor
  format: NormalizedFormatConfig
  flyout: NormalizedFlyoutConfig
}

const HAS_SECONDS = /%[ST]/

export default function ClockWidget({ id, placement, monitor, format, flyout }: Props) {
  const [currentTime, setCurrentTime] = createState(GLib.DateTime.new_now_local())
  const [useAlt, setUseAlt] = createState(false)

  const primaryFormat = placement.isVertical && format.vertical ? format.vertical : format.primary
  const altFormat = placement.isVertical && format.verticalAlt ? format.verticalAlt : format.alt
  const hasAlt = altFormat.length > 0

  const activeFormatHasSeconds = createComputed(() =>
    HAS_SECONDS.test(hasAlt && useAlt() ? altFormat : primaryFormat),
  )

  const labelText = createComputed(() => {
    const fmt = hasAlt && useAlt() ? altFormat : primaryFormat
    return currentTime().format(fmt) ?? ""
  })

  // Self-scheduling timer: 1 s when showing seconds, minute-aligned otherwise.
  // Follows Waybar's approach — fire at the next minute boundary then every 60 s.
  // Maximum clock error is ≤ 1 s in both modes.
  let activeTimer: Timer | null = null

  createEffect(() => {
    const hasSeconds = activeFormatHasSeconds()

    activeTimer?.cancel()
    setCurrentTime(GLib.DateTime.new_now_local())

    function tick() {
      setCurrentTime(GLib.DateTime.new_now_local())
      schedule()
    }

    function schedule() {
      activeTimer?.cancel()
      if (hasSeconds) {
        activeTimer = timeout(1000, tick)
      } else {
        const now = GLib.DateTime.new_now_local()
        const msUntilNextMinute =
          (60 - now.get_second()) * 1000 - Math.floor(now.get_microsecond() / 1000)
        activeTimer = timeout(Math.max(500, msUntilNextMinute), tick)
      }
    }

    schedule()
  })

  onCleanup(() => activeTimer?.cancel())

  return (
    <FlyoutButton
      widgetClass="widget-clock-button"
      placement={placement}
      monitor={monitor}
      id={id}
      flyoutLabel="calendar-menu"
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
