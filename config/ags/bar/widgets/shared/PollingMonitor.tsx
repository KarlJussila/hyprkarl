import { createComputed, createState } from "ags"
import { Gtk } from "ags/gtk4"
import { type BarOrientation } from "../../layout/placement.ts"
import Button from "../../primitives/Button.tsx"
import { useWidgetCommands } from "./useWidgetCommands.ts"
import { substituteTokens } from "./template.ts"
import type { WidgetClicks } from "./types.ts"

export type PollingMonitorFormat = {
  primary: string
  alt: string
  vertical: string
  verticalAlt: string
}

export type PollingMonitorDecimals = {
  primary: number
  alt: number
  vertical: number
  verticalAlt: number
}

type Props = {
  widgetClass: string
  orientation: BarOrientation
  icon: string
  format: PollingMonitorFormat
  decimals: PollingMonitorDecimals
  tooltip: string
  revealDurationMs: number
  commands: WidgetClicks
  buildSubstitutions: (decimals: number) => Record<string, string | undefined>
}

export default function PollingMonitorWidget({
  widgetClass,
  orientation,
  icon,
  format,
  decimals,
  tooltip,
  revealDurationMs,
  commands,
  buildSubstitutions,
}: Props) {
  const [labelVisible, setLabelVisible] = createState(false)
  const [useAlt, setUseAlt] = createState(false)

  const isVertical = orientation === "vertical"
  const primaryFormat = isVertical && format.vertical ? format.vertical : format.primary
  const altFormat = isVertical && format.verticalAlt ? format.verticalAlt : format.alt
  const primaryDecimals = Math.round(isVertical ? decimals.vertical : decimals.primary)
  const altDecimals = Math.round(isVertical ? decimals.verticalAlt : decimals.alt)
  const hasAlt = altFormat.length > 0

  const tooltipText = tooltip
    ? createComputed(() => substituteTokens(tooltip, buildSubstitutions(primaryDecimals)))
    : undefined

  const labelText = primaryFormat
    ? createComputed(() => {
        const [fmt, d] = hasAlt && useAlt() ? [altFormat, altDecimals] : [primaryFormat, primaryDecimals]
        return substituteTokens(fmt, buildSubstitutions(d))
      })
    : null

  const toggleLabel = labelText ? () => setLabelVisible(!labelVisible()) : undefined
  const toggleAlt = hasAlt ? () => setUseAlt(!useAlt()) : undefined

  const { execPrimary, execSecondary, execTertiary } = useWidgetCommands({
    commands,
    primaryFallback: toggleLabel,
    secondaryFallback: toggleAlt,
    tokens: { "toggle-label": toggleLabel, "toggle-alt": toggleAlt },
  })

  return (
    <Button
      class={`${widgetClass}-button widget-glyph-button`}
      orientation={orientation}
      tooltipText={tooltipText}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execTertiary={execTertiary}
    >
      <box
        class={`${widgetClass}-display widget-icon-display is-${orientation}`}
        orientation={isVertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
        spacing={0}
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
      >
        <label class={`${widgetClass}-icon`} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} label={icon} />
        {labelText && (
          <revealer
            transitionType={isVertical ? Gtk.RevealerTransitionType.SLIDE_DOWN : Gtk.RevealerTransitionType.SLIDE_RIGHT}
            transitionDuration={revealDurationMs}
            revealChild={labelVisible}
          >
            <label
              class={`${widgetClass}-percent widget-readout widget-readout-percent`}
              halign={Gtk.Align.CENTER}
              valign={Gtk.Align.CENTER}
              xalign={0.5}
              label={labelText}
            />
          </revealer>
        )}
      </box>
    </Button>
  )
}
