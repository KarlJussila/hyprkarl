import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  normalizeSimpleTooltipConfig,
  normalizeStringValue,
  type NormalizedSimpleTooltipConfig,
} from "../shared/normalize.ts"
import { normalizeCommands } from "./normalize.ts"
import type { NormalizedCommandConfig } from "./types.ts"
import MenuWidget from "./MenuWidget.tsx"

const menuDefaults = {
  icon: "",
  commands: {
    primary: "hk-menu",
  },
  tooltip: {
    enabled: true,
    text: "",
  },
} satisfies {
  icon: string
  commands: NormalizedCommandConfig
  tooltip: NormalizedSimpleTooltipConfig
}

export default createWidgetSpec({
  kind: "menu",
  defaults: menuDefaults,
  schema: {
    icon: normalizeStringValue,
    commands: normalizeCommands,
    tooltip: normalizeSimpleTooltipConfig,
  },
  render: ({ config, placement }) => (
    <MenuWidget
      orientation={placement.orientation}
      icon={config.icon}
      commands={config.commands}
      tooltip={config.tooltip}
    />
  ),
})
