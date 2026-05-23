import { createComputed, createState } from "ags"
import { Gtk } from "ags/gtk4"
import { type BarOrientation } from "../../layout/placement.ts"
import Button from "../../primitives/Button.tsx"
import { createRamState } from "./ramState.ts"
import { substituteTokens } from "../shared/template.ts"
import type { NormalizedDecimalsConfig, NormalizedFormatConfig } from "../shared/normalize.ts"

type Props = {
  orientation: BarOrientation
  icon: string
  format: NormalizedFormatConfig
  decimals: NormalizedDecimalsConfig
  tooltip: string
  interval: number
  revealDurationMs: number
}

function formatPercent(fraction: number, decimals: number): string {
  return (fraction * 100).toFixed(decimals)
}

function formatSize(kb: number, decimals: number): string {
  if (kb >= 1024 * 1024) {
    return `${(kb / (1024 * 1024)).toFixed(decimals)}G`
  }
  return `${(kb / 1024).toFixed(decimals)}M`
}

export default function RamWidget({
  orientation,
  icon,
  format,
  decimals,
  tooltip,
  interval,
  revealDurationMs,
}: Props) {
  const ram = createRamState(interval)
  const [labelVisible, setLabelVisible] = createState(false)
  const [useAlt, setUseAlt] = createState(false)

  const isVertical = orientation === "vertical"
  const primaryFormat = isVertical && format.vertical ? format.vertical : format.primary
  const altFormat = isVertical && format.verticalAlt ? format.verticalAlt : format.alt
  const primaryDecimals = Math.round(isVertical ? decimals.vertical : decimals.primary)
  const altDecimals = Math.round(isVertical ? decimals.verticalAlt : decimals.alt)
  const hasAlt = altFormat.length > 0

  function buildSubstitutions(d: number) {
    const ramFreeKb = ram.ramTotalKb() - ram.ramUsedKb()
    const swapFreeKb = ram.swapTotalKb() - ram.swapUsedKb()
    return {
      ram: formatPercent(ram.ramFraction(), d),
      ram_used: formatSize(ram.ramUsedKb(), d),
      ram_total: formatSize(ram.ramTotalKb(), d),
      ram_free: formatSize(ramFreeKb, d),
      swap: formatPercent(ram.swapFraction(), d),
      swap_used: formatSize(ram.swapUsedKb(), d),
      swap_total: formatSize(ram.swapTotalKb(), d),
      swap_free: formatSize(swapFreeKb, d),
    }
  }

  const tooltipText = createComputed(() => substituteTokens(tooltip, buildSubstitutions(primaryDecimals)))

  const labelText = primaryFormat
    ? createComputed(() => {
        const [fmt, d] = hasAlt && useAlt() ? [altFormat, altDecimals] : [primaryFormat, primaryDecimals]
        return substituteTokens(fmt, buildSubstitutions(d))
      })
    : null

  return (
    <Button
      class="widget-ram-button widget-glyph-button"
      orientation={orientation}
      tooltipText={tooltipText}
      execPrimary={labelText ? () => setLabelVisible(!labelVisible()) : undefined}
      execSecondary={hasAlt ? () => setUseAlt(!useAlt()) : undefined}
    >
      <box
        class={`widget-ram-display widget-icon-display is-${orientation}`}
        orientation={isVertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
        spacing={0}
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
      >
        <label class="widget-ram-icon" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} label={icon} />
        {labelText && (
          <revealer
            transitionType={isVertical ? Gtk.RevealerTransitionType.SLIDE_DOWN : Gtk.RevealerTransitionType.SLIDE_RIGHT}
            transitionDuration={revealDurationMs}
            revealChild={labelVisible}
          >
            <label
              class="widget-ram-percent widget-readout widget-readout-percent"
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
