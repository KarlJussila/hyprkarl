import { execAsync } from "ags/process"
import { Gtk } from "ags/gtk4"
import { type BarOrientation } from "../../layout/placement.ts"
import Button from "../../primitives/Button.tsx"
import type { NormalizedSimpleTooltipConfig } from "../shared/normalize.ts"
import { getRecordingController } from "./controller.ts"

type Props = {
  orientation: BarOrientation
  icon: string
  command: string
  tooltip: NormalizedSimpleTooltipConfig
}

export default function RecordingWidget({ orientation, icon, command, tooltip }: Props) {
  const isVertical = orientation === "vertical"
  const controller = getRecordingController()

  return (
    <Button
      class="widget-recording-button widget-glyph-button"
      orientation={orientation}
      visible={controller.active}
      tooltipText={tooltip.enabled && tooltip.text ? tooltip.text : undefined}
      execPrimary={() => execAsync(command).catch(() => {})}
    >
      <box class="widget-recording-content" hexpand={isVertical} halign={Gtk.Align.CENTER}>
        <label class="widget-recording-glyph" xalign={0.5} label={icon} />
      </box>
    </Button>
  )
}
