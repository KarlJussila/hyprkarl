import { createComputed, createState } from "ags"
import { Gtk } from "ags/gtk4"
import { type BarOrientation } from "../../layout/placement.ts"
import Button from "../../primitives/Button.tsx"
import { resolveCommand } from "./resolveCommand.ts"
import { substituteTokens } from "./template.ts"
import type { NormalizedClickCommandsConfig, NormalizedDecimalsConfig, NormalizedFormatConfig, NormalizedSimpleTooltipConfig } from "./normalize.ts"

type Props = {
  widgetClass: string
  orientation: BarOrientation
  icon: string
  format: NormalizedFormatConfig
  decimals: NormalizedDecimalsConfig
  tooltip: NormalizedSimpleTooltipConfig
  revealDurationMs: number
  commands: NormalizedClickCommandsConfig
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

  const tooltipText = tooltip.enabled && tooltip.text
    ? createComputed(() => substituteTokens(tooltip.text, buildSubstitutions(primaryDecimals)))
    : undefined

  const labelText = primaryFormat
    ? createComputed(() => {
        const [fmt, d] = hasAlt && useAlt() ? [altFormat, altDecimals] : [primaryFormat, primaryDecimals]
        return substituteTokens(fmt, buildSubstitutions(d))
      })
    : null

  const toggleLabel = labelText ? () => setLabelVisible(!labelVisible()) : undefined
  const toggleAlt = hasAlt ? () => setUseAlt(!useAlt()) : undefined

  const tokens = {
    "toggle-label": toggleLabel,
    "toggle-alt": toggleAlt,
  }

  const execPrimary = resolveCommand(commands.primary, toggleLabel, tokens)
  const execSecondary = resolveCommand(commands.secondary, toggleAlt, tokens)
  const execMiddle = resolveCommand(commands.tertiary, undefined, tokens)

  return (
    <Button
      class={`${widgetClass}-button widget-glyph-button`}
      orientation={orientation}
      tooltipText={tooltipText}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execMiddle={execMiddle}
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
