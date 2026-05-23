import { createComputed, createState } from "ags"
import { Gtk } from "ags/gtk4"
import { type BarOrientation } from "../../layout/placement.ts"
import Button from "../../primitives/Button.tsx"
import { createCpuState } from "./cpuState.ts"
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

export default function CpuWidget({ orientation, icon, format, decimals, tooltip, interval, revealDurationMs }: Props) {
  const cpu = createCpuState(interval)
  const [labelVisible, setLabelVisible] = createState(false)
  const [useAlt, setUseAlt] = createState(false)

  const isVertical = orientation === "vertical"
  const primaryFormat = isVertical && format.vertical ? format.vertical : format.primary
  const altFormat = isVertical && format.verticalAlt ? format.verticalAlt : format.alt
  const primaryDecimals = Math.round(isVertical ? decimals.vertical : decimals.primary)
  const altDecimals = Math.round(isVertical ? decimals.verticalAlt : decimals.alt)
  const hasAlt = altFormat.length > 0

  function buildSubstitutions(d: number) {
    const tempVal = cpu.temp()
    const coreLines = cpu.coreUsages().map((u, i) => `Core ${i}: ${(u * 100).toFixed(d)}%`)
    return {
      usage: (cpu.usage() * 100).toFixed(d),
      temp: tempVal !== null ? tempVal.toFixed(d) : undefined,
      cores: coreLines.join("\n"),
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
      class="widget-cpu-button widget-glyph-button"
      orientation={orientation}
      tooltipText={tooltipText}
      execPrimary={labelText ? () => setLabelVisible(!labelVisible()) : undefined}
      execSecondary={hasAlt ? () => setUseAlt(!useAlt()) : undefined}
    >
      <box
        class={`widget-cpu-display widget-icon-display is-${orientation}`}
        orientation={isVertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
        spacing={0}
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
      >
        <label class="widget-cpu-icon" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} label={icon} />
        {labelText && (
          <revealer
            transitionType={isVertical ? Gtk.RevealerTransitionType.SLIDE_DOWN : Gtk.RevealerTransitionType.SLIDE_RIGHT}
            transitionDuration={revealDurationMs}
            revealChild={labelVisible}
          >
            <label
              class="widget-cpu-percent widget-readout widget-readout-percent"
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
