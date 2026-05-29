export type WorkspaceVisibility = {
  alwaysShow: Array<number>
  includeFocused: boolean
  includeOccupied: boolean
  excludeSpecial: boolean
}

// Back-compat aliases.
export type NormalizedWorkspaceVisibilityConfig = WorkspaceVisibility
export type WorkspaceVisibilityConfig = Partial<WorkspaceVisibility>
