import { execAsync } from "ags/process"
import { Gtk } from "ags/gtk4"
import { type BarOrientation } from "../../layout/placement"
import Button from "../../primitives/Button"
import type { NormalizedCommandConfig } from "./types.ts"

type Props = {
  orientation: BarOrientation
  icon: string
  commands: NormalizedCommandConfig
}

export default function MenuWidget({ orientation, icon, commands }: Props) {
  const isVertical = orientation === "vertical"

  return (
    <Button
      class="widget-menu-button"
      orientation={orientation}
      execPrimary={() => execAsync(commands.primary).catch(() => {})}
      execSecondary={commands.secondary
        ? () => execAsync(commands.secondary!).catch(() => {})
        : undefined}
    >
      <box
        class="widget-menu-content"
        hexpand={isVertical}
        halign={Gtk.Align.CENTER}
      >
        <label class="widget-menu-glyph" xalign={0.5} label={icon} />
      </box>
    </Button>
  )
}
