import type {
  NormalizedWorkspaceVisibilityConfig,
  WorkspaceVisibilityConfig,
} from "./types.ts"
import {
  childContext,
  normalizeBoolean,
  normalizeIntegerList,
  normalizeObjectConfig,
  widgetContext,
} from "../shared/normalize.ts"

export function normalizeVisibility(
  id: string,
  visibility: WorkspaceVisibilityConfig | undefined,
  defaults: NormalizedWorkspaceVisibilityConfig,
): NormalizedWorkspaceVisibilityConfig {
  const context = widgetContext(id, "visibility")
  const rawVisibility = normalizeObjectConfig(context, visibility)

  return {
    alwaysShow: normalizeIntegerList(
      childContext(context, "alwaysShow"),
      rawVisibility?.alwaysShow ?? defaults.alwaysShow,
      true,
    ),
    includeFocused: normalizeBoolean(
      childContext(context, "includeFocused"),
      rawVisibility?.includeFocused,
      defaults.includeFocused,
    ),
    includeOccupied: normalizeBoolean(
      childContext(context, "includeOccupied"),
      rawVisibility?.includeOccupied,
      defaults.includeOccupied,
    ),
    excludeSpecial: normalizeBoolean(
      childContext(context, "excludeSpecial"),
      rawVisibility?.excludeSpecial,
      defaults.excludeSpecial,
    ),
  }
}
