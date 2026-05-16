import type {
  CommandConfig,
  NormalizedCommandConfig,
} from "./types.ts"
import {
  childContext,
  normalizeObjectConfig,
  normalizeOptionalCommand,
  normalizeRequiredCommand,
  widgetContext,
} from "../shared/normalize.ts"

export function normalizeCommands(
  id: string,
  commands: CommandConfig | undefined,
  defaults: NormalizedCommandConfig,
): NormalizedCommandConfig {
  const context = widgetContext(id, "commands")
  const rawCommands = normalizeObjectConfig(context, commands)

  return {
    primary: normalizeRequiredCommand(
      childContext(context, "primary"),
      rawCommands?.primary,
      defaults.primary,
    ),
    secondary: normalizeOptionalCommand(
      childContext(context, "secondary"),
      rawCommands?.secondary,
      defaults.secondary,
    ),
  }
}
