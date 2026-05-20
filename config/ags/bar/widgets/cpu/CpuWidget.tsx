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
  tooltip: string
  interval: number
}

export default function CpuWidget({ orientation, icon, format, tooltip, interval }: Props) {
  const cpu = createCpuState(interval)
  const [labelVisible, setLabelVisible] = createState(false)

  const tooltipText = createComputed(() => {
    const tempVal = cpu.temp()
    const coreLines = cpu.coreUsages().map((u, i) => `Core ${i}: ${Math.round(u * 100)}%`)
    return substituteTokens(tooltip, {
      usage: String(Math.round(cpu.usage() * 100)),
      temp: tempVal !== null ? String(Math.round(tempVal)) : undefined,
      cores: coreLines.join("\n"),
    })
  })

  const isVertical = orientation === "vertical"

  const labelText = format
    ? createComputed(() => {
        const tempVal = cpu.temp()
        return substituteTokens(format, {
          usage: String(Math.round(cpu.usage() * 100)),
          temp: tempVal !== null ? String(Math.round(tempVal)) : undefined,
        })
      })
    : null

  return (
    <Button
      class="widget-cpu-button widget-glyph-button"
      orientation={orientation}
      tooltipText={tooltipText}
      execPrimary={labelText ? () => setLabelVisible(!labelVisible()) : undefined}
    >
      <box
        class={`widget-cpu-display is-${orientation}`}
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
              class="widget-cpu-percent"
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
