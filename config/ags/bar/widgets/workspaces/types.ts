export type WorkspaceVisibilityConfig = {
  alwaysShow?: Array<number>
  includeFocused?: boolean
  includeOccupied?: boolean
  excludeSpecial?: boolean
}

export type NormalizedWorkspaceVisibilityConfig = {
  alwaysShow: Array<number>
  includeFocused: boolean
  includeOccupied: boolean
  excludeSpecial: boolean
}
