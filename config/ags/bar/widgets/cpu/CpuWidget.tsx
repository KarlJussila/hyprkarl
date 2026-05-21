import { createComputed, createState } from "ags"
import { Gtk } from "ags/gtk4"
import { type BarOrientation } from "../../layout/placement.ts"
import Button from "../../primitives/Button.tsx"
import { createCpuState } from "./cpuState.ts"
import { substituteTokens } from "../shared/template.ts"

type Props = {
  orientation: BarOrientation
  icon: string
  format: string
  formatAlt: string
  formatVertical: string
  formatVerticalAlt: string
  tooltip: string
  interval: number
}

export default function CpuWidget({ orientation, icon, format, formatAlt, formatVertical, formatVerticalAlt, tooltip, interval }: Props) {
  const cpu = createCpuState(interval)
  const [labelVisible, setLabelVisible] = createState(false)
  const [useAlt, setUseAlt] = createState(false)

  const isVertical = orientation === "vertical"
  const primaryFormat = isVertical && formatVertical ? formatVertical : format
  const altFormat = isVertical && formatVerticalAlt ? formatVerticalAlt : formatAlt
  const hasAlt = altFormat.length > 0

  const tooltipText = createComputed(() => {
    const tempVal = cpu.temp()
    const coreLines = cpu.coreUsages().map((u, i) => `Core ${i}: ${Math.round(u * 100)}%`)
    return substituteTokens(tooltip, {
      usage: String(Math.round(cpu.usage() * 100)),
      temp: tempVal !== null ? String(Math.round(tempVal)) : undefined,
      cores: coreLines.join("\n"),
    })
  })

  function buildSubstitutions() {
    const tempVal = cpu.temp()
    return {
      usage: String(Math.round(cpu.usage() * 100)),
      temp: tempVal !== null ? String(Math.round(tempVal)) : undefined,
    }
  }

  const labelText = primaryFormat
    ? createComputed(() => {
        const fmt = hasAlt && useAlt() ? altFormat : primaryFormat
        return substituteTokens(fmt, buildSubstitutions())
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
            transitionDuration={200}
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
