import type {
  NormalizedMenuWidgetConfig,
  WidgetDefinitionByKind,
} from "../../configuration.ts"
import {
  normalizeCommands,
  normalizeStringValue,
  widgetContext,
} from "../shared/normalize.ts"

const menuDefaults: Omit<NormalizedMenuWidgetConfig, "kind"> = {
  icon: "",
  commands: {
    primary: "hyprkarl-menu",
  },
}

export function normalizeMenuWidgetConfig(
  id: string,
  definition: WidgetDefinitionByKind["menu"],
): NormalizedMenuWidgetConfig {
  return {
    kind: "menu",
    icon: normalizeStringValue(
      widgetContext(id, "icon"),
      definition.icon,
      menuDefaults.icon,
    ),
    commands: normalizeCommands(id, definition.commands, menuDefaults.commands),
  }
}

