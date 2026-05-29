import { createComputed, createEffect, createState, onCleanup, type Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import { timeout, type Timer } from "ags/time"
import GLib from "gi://GLib?version=2.0"
import Button from "../../primitives/Button.tsx"
import { useWidgetCommands } from "../shared/useWidgetCommands.ts"
import { mergeConfig, defaultFlyout, type WidgetClicks, type WidgetFlyout, type WidgetProps } from "../shared/types.ts"

export type ClockConfig = {
  format?: { primary?: string; alt?: string; vertical?: string; verticalAlt?: string }
  tooltip?: string
  commands?: WidgetClicks
  flyout?: WidgetFlyout
}

type ClockDefaults = {
  format: { primary: string; alt: string; vertical: string; verticalAlt: string }
  tooltip: string
  commands: WidgetClicks
  flyout: WidgetFlyout
}

export const defaults: ClockDefaults = {
  format: { primary: "%a %-I:%M %p", alt: "", vertical: "%I\n%M\n%p", verticalAlt: "" },
  tooltip: "",
  commands: {},
  flyout: defaultFlyout,
}

const HAS_SECONDS = /%[ST]/

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

function CalendarFlyoutContent({ currentTime }: { currentTime: Accessor<GLib.DateTime> }) {
  return (
    <box orientation={Gtk.Orientation.VERTICAL}>
      <label label={currentTime(formatDate)} />
      <Gtk.Calendar showHeading={false} canTarget={false} />
    </box>
  )
}

export default function Clock({ id, config, placement, monitor }: WidgetProps<ClockConfig>) {
  const cfg = mergeConfig(defaults, config)
  const { format, tooltip, commands, flyout } = cfg

  const [currentTime, setCurrentTime] = createState(GLib.DateTime.new_now_local())
  const [useAlt, setUseAlt] = createState(false)

  const primaryFormat = placement.isVertical && format.vertical ? format.vertical : format.primary
  const altFormat = placement.isVertical && format.verticalAlt ? format.verticalAlt : format.alt
  const hasAlt = altFormat.length > 0

  const toggleAlt = hasAlt ? () => setUseAlt(!useAlt()) : undefined

  const { execPrimary, execSecondary, execTertiary, triggerSetup } = useWidgetCommands({
    commands,
    secondaryFallback: toggleAlt,
    tokens: { "toggle-alt": toggleAlt },
    flyout: {
      config: flyout,
      placement,
      monitor,
      id,
      label: "calendar-menu",
      renderContent: () => <CalendarFlyoutContent currentTime={currentTime} />,
    },
  })

  const activeFormatHasSeconds = createComputed(() =>
    HAS_SECONDS.test(hasAlt && useAlt() ? altFormat : primaryFormat),
  )

  const labelText = createComputed(() => {
    const fmt = hasAlt && useAlt() ? altFormat : primaryFormat
    return currentTime().format(fmt) ?? ""
  })

  const tooltipText = tooltip
    ? createComputed(() => currentTime().format(tooltip) ?? "")
    : undefined

  // Self-scheduling timer: 1 s when showing seconds, minute-aligned otherwise.
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
    <Button
      class={`widget-clock-button is-${placement.orientation}`}
      orientation={placement.orientation}
      tooltipText={tooltipText}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execTertiary={execTertiary}
      $={triggerSetup}
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
    </Button>
  )
}
