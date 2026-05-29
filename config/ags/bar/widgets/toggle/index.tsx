import { createComputed } from "ags"
import { Gtk } from "ags/gtk4"
import type { SwitchMetrics } from "../../primitives/switchTypes.ts"
import Switch from "../../primitives/Switch.tsx"
import { mergeConfig, type WidgetProps } from "../shared/types.ts"
import { getToggleController } from "./controller.ts"

type ToggleCommands = { on: string; off: string; sync: string }
type ToggleTooltip = { active: string; inactive: string }

export type ToggleConfig = {
  commands?: Partial<ToggleCommands>
  endpoint?: string
  switch?: Partial<SwitchMetrics>
  tooltip?: Partial<ToggleTooltip>
}

type ToggleDefaults = {
  commands: ToggleCommands
  endpoint: string
  switch: SwitchMetrics
  tooltip: ToggleTooltip
}

export const defaults: ToggleDefaults = {
  // Placeholder commands: a bare `kind: "toggle"` renders a visible, harmless
  // widget in the off state (`sync: "false"` always exits non-zero).
  commands: { on: "true", off: "true", sync: "false" },
  endpoint: "",
  switch: {
    thumbSize: 16,
    trackHeight: 12,
    trackLength: 24,
    thumbPadding: 7,
    borderWidth: 2,
    fontSize: 8,
    fontFamily: "JetBrains Mono Nerd Font Propo",
    glyphs: {
      on: { glyph: "?", glyphOffset: [0, 0] },
      off: { glyph: "?", glyphOffset: [0, 0] },
    },
  },
  tooltip: { active: "", inactive: "" },
}

export default function ToggleWidget({ config, placement }: WidgetProps<ToggleConfig>) {
  const cfg = mergeConfig(defaults, config)
  const { commands, endpoint, switch: switchMetrics, tooltip } = cfg
  const controller = getToggleController(commands, endpoint)
  const isVertical = placement.orientation === "vertical"

  const tooltipText = tooltip.active || tooltip.inactive
    ? createComputed(() => controller.active() ? tooltip.active : tooltip.inactive)
    : undefined

  return (
    <Switch
      class="widget-toggle-switch widget-glyph-button"
      hexpand={isVertical}
      halign={Gtk.Align.FILL}
      orientation={placement.orientation}
      metrics={switchMetrics}
      active={controller.active}
      tooltipText={tooltipText}
      onToggle={(next) => {
        controller.toggle(commands, next)
      }}
    />
  )
}
