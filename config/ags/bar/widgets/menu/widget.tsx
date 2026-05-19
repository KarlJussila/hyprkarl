import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizeStringValue } from "../shared/normalize.ts"
import { normalizeCommands } from "./normalize.ts"
import type { NormalizedCommandConfig } from "./types.ts"
import MenuWidget from "./MenuWidget.tsx"

const menuDefaults = {
  icon: "",
  commands: {
    primary: "hk-menu",
  },
} satisfies {
  icon: string
  commands: NormalizedCommandConfig
}

export default createWidgetSpec({
  kind: "menu",
  defaults: menuDefaults,
  schema: {
    icon: normalizeStringValue,
    commands: normalizeCommands,
  },
  render: ({ config, placement }) => (
    <MenuWidget
      orientation={placement.orientation}
      icon={config.icon}
      commands={config.commands}
    />
  ),
})
