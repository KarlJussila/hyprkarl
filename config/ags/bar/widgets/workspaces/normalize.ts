import type {
  NormalizedWorkspaceVisibilityConfig,
  WorkspaceVisibilityConfig,
} from "./types.ts"
import {
  childContext,
  normalizeBoolean,
  normalizeIntegerList,
  normalizeObjectConfig,
  type ValidationContext,
} from "../shared/normalize.ts"

export function normalizeVisibility(
  ctx: ValidationContext,
  visibility: WorkspaceVisibilityConfig | undefined,
  defaults: NormalizedWorkspaceVisibilityConfig,
): NormalizedWorkspaceVisibilityConfig {
  const rawVisibility = normalizeObjectConfig(ctx, visibility) as WorkspaceVisibilityConfig | undefined

  return {
    alwaysShow: normalizeIntegerList(
      childContext(ctx, "alwaysShow"),
      rawVisibility?.alwaysShow ?? defaults.alwaysShow,
      true,
    ),
    includeFocused: normalizeBoolean(childContext(ctx, "includeFocused"), rawVisibility?.includeFocused, defaults.includeFocused),
    includeOccupied: normalizeBoolean(childContext(ctx, "includeOccupied"), rawVisibility?.includeOccupied, defaults.includeOccupied),
    excludeSpecial: normalizeBoolean(childContext(ctx, "excludeSpecial"), rawVisibility?.excludeSpecial, defaults.excludeSpecial),
  }
}
