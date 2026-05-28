import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  composeObject,
  normalizeRequiredCommand,
  normalizeStringValue,
} from "../shared/normalize.ts"
import { normalizeSwitchMetrics } from "../../primitives/switchNormalize.ts"
import ToggleWidget from "./ToggleWidget.tsx"

const normalizeToggleTooltipConfig = composeObject({
  active: normalizeStringValue,
  inactive: normalizeStringValue,
})

const normalizeToggleCommands = composeObject({
  on: normalizeRequiredCommand,
  off: normalizeRequiredCommand,
  sync: normalizeRequiredCommand,
})

export default createWidgetSpec({
  kind: "toggle",
  defaults: {
    // Placeholder commands: a bare `kind: "toggle"` renders a visible, harmless
    // widget in the off state (`sync: "false"` always exits non-zero).
    commands: {
      on: "true",
      off: "true",
      sync: "false",
    },
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
    tooltip: {
      active: "",
      inactive: "",
    },
  },
  schema: {
    commands: normalizeToggleCommands,
    endpoint: normalizeStringValue,
    switch: normalizeSwitchMetrics,
    tooltip: normalizeToggleTooltipConfig,
  },
  render: (args) => (
    <ToggleWidget {...args} />
  ),
})
