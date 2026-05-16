import {
  createWidgetSpec,
  type WidgetConfig,
} from "../shared/widgetSpec.tsx"
import {
  normalizeStringValue,
  widgetContext,
} from "../shared/normalize.ts"
import { normalizeCommands } from "./normalize.ts"
import type {
  CommandConfig,
  NormalizedCommandConfig,
} from "./types.ts"
import MenuWidget from "./MenuWidget.tsx"

export type MenuWidgetConfig = WidgetConfig<"menu", {
  icon?: string
  commands?: CommandConfig
}>

const menuDefaults = {
  icon: "",
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
  resolve(
    id: string,
    definition: MenuWidgetConfig,
    defaults,
  ) {
    return {
      kind: "menu",
      icon: normalizeStringValue(
        widgetContext(id, "icon"),
        definition.icon,
        defaults.icon,
      ),
      commands: normalizeCommands(id, definition.commands, defaults.commands),
    }
  },
  render: ({ config, placement }) => (
    <MenuWidget
      orientation={placement.orientation}
      icon={config.icon}
      commands={config.commands}
    />
  ),
})
