import type {
  CommandConfig,
  NormalizedCommandConfig,
} from "./types.ts"
import {
  childContext,
  normalizeObjectConfig,
  normalizeOptionalCommand,
  normalizeRequiredCommand,
  type ValidationContext,
} from "../shared/normalize.ts"

export function normalizeCommands(
  ctx: ValidationContext,
  commands: CommandConfig | undefined,
  defaults: NormalizedCommandConfig,
): NormalizedCommandConfig {
  const rawCommands = normalizeObjectConfig(ctx, commands) as CommandConfig | undefined

  return {
    primary: normalizeRequiredCommand(childContext(ctx, "primary"), rawCommands?.primary, defaults.primary),
    secondary: normalizeOptionalCommand(childContext(ctx, "secondary"), rawCommands?.secondary, defaults.secondary),
    tertiary: normalizeOptionalCommand(childContext(ctx, "tertiary"), rawCommands?.tertiary, defaults.tertiary),
  }
}
