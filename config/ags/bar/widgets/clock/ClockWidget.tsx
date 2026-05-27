import { createComputed, createEffect, createState, onCleanup } from "ags"
import { Gtk } from "ags/gtk4"
import { timeout, type Timer } from "ags/time"
import GLib from "gi://GLib?version=2.0"
import Button from "../../primitives/Button.tsx"
import CalendarFlyoutContent from "./CalendarFlyoutContent.tsx"
import { useWidgetCommands } from "../shared/useWidgetCommands.ts"
import type { WidgetRenderArgs } from "../shared/widgetSpec.tsx"
import type { NormalizedFlyoutConfig } from "../../flyout/flyoutTypes.ts"
import type { NormalizedClickCommandsConfig, NormalizedFormatConfig, NormalizedSimpleTooltipConfig } from "../shared/normalize.ts"

type Config = {
  format: NormalizedFormatConfig
  flyout: NormalizedFlyoutConfig
  tooltip: NormalizedSimpleTooltipConfig
  commands: NormalizedClickCommandsConfig
}

const HAS_SECONDS = /%[ST]/

export default function ClockWidget({ id, config, placement, monitor }: WidgetRenderArgs<Config>) {
  const { format, flyout, tooltip, commands } = config
  const [currentTime, setCurrentTime] = createState(GLib.DateTime.new_now_local())
  const [useAlt, setUseAlt] = createState(false)

  const primaryFormat = placement.isVertical && format.vertical ? format.vertical : format.primary
  const altFormat = placement.isVertical && format.verticalAlt ? format.verticalAlt : format.alt
  const hasAlt = altFormat.length > 0

  const toggleAlt = hasAlt ? () => setUseAlt(!useAlt()) : undefined

  const { execPrimary, execSecondary, execMiddle, triggerSetup } = useWidgetCommands({
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

  const tooltipText = tooltip.enabled && tooltip.text
    ? createComputed(() => currentTime().format(tooltip.text) ?? "")
    : undefined

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
    <Button
      class={`widget-clock-button is-${placement.orientation}`}
      orientation={placement.orientation}
      tooltipText={tooltipText}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execMiddle={execMiddle}
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
