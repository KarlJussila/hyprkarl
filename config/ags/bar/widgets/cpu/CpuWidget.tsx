import { createComputed, createState } from "ags"
import { Gtk } from "ags/gtk4"
import { type BarOrientation } from "../../layout/placement.ts"
import Button from "../../primitives/Button.tsx"
import { createCpuState } from "./cpuState.ts"

type Props = {
  orientation: BarOrientation
  icon: string
  showPercentage: boolean
  warningThreshold: number
  interval: number
}

export default function CpuWidget({ orientation, icon, showPercentage, warningThreshold, interval }: Props) {
  const cpu = createCpuState(interval)
  const [percentVisible, setPercentVisible] = createState(showPercentage)

  const displayClass = cpu.usage((u) =>
    `widget-cpu-display orientation-${orientation} is-${orientation}${u >= warningThreshold ? " is-high" : ""}`,
  )
  const percentLabel = cpu.usage((u) => `${Math.round(u * 100)}%`)
  const tooltipText = createComputed(() => {
    const header = `CPU ${Math.round(cpu.usage() * 100)}%`
    const cores = cpu.coreUsages()
    if (cores.length === 0) return header
    const coreLines = cores.map((u, i) => `Core ${i}: ${Math.round(u * 100)}%`)
    return [header, ...coreLines].join("\n")
  })

  const isVertical = orientation === "vertical"

  return (
    <Button
      class="widget-cpu-button"
      orientation={orientation}
      tooltipText={tooltipText}
      execPrimary={() => setPercentVisible(!percentVisible())}
    >
      <box
        class={displayClass}
        orientation={isVertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
        spacing={0}
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
      >
        <label class="widget-cpu-icon" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} label={icon} />
        <revealer
          transitionType={isVertical ? Gtk.RevealerTransitionType.SLIDE_DOWN : Gtk.RevealerTransitionType.SLIDE_RIGHT}
          transitionDuration={200}
          revealChild={percentVisible}
        >
          <label
            class="widget-cpu-percent"
            halign={Gtk.Align.CENTER}
            valign={Gtk.Align.CENTER}
            xalign={0.5}
            label={percentLabel}
          />
        </revealer>
      </box>
    </Button>
  )
}
