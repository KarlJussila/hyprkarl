import AstalHyprland from "gi://AstalHyprland"
import type { NormalizedWorkspaceVisibilityConfig } from "./types"

export type VisibleWorkspace = {
  id: number
  isEmpty: boolean
}

function compareWorkspaceIds(a: VisibleWorkspace, b: VisibleWorkspace) {
  return a.id - b.id
}

function uniqueWorkspacesById(workspaces: Array<VisibleWorkspace>) {
  return Array.from(new Map(workspaces.map((workspace) => [workspace.id, workspace])).values())
}

function activeSpecialWorkspaceIds(hyprland: AstalHyprland.Hyprland) {
  return new Set(
    hyprland.monitors
      .map((monitor) => monitor.specialWorkspace?.id)
      .filter((id): id is number => id !== undefined && id !== null),
  )
}

function isSpecialWorkspaceName(name: string) {
  return name.startsWith("special:")
}

function findWorkspaceById(
  hyprland: AstalHyprland.Hyprland,
  workspaces: Array<AstalHyprland.Workspace>,
  id: number,
) {
  return workspaces.find((workspace) => workspace.id === id) ?? hyprland.get_workspace(id)
}

function isVisibleWorkspaceCandidate(
  workspace: AstalHyprland.Workspace | null | undefined,
  specialWorkspaceIds: Set<number>,
  excludeSpecial: boolean,
) {
  if (!workspace) return false
  if (!excludeSpecial) return true

  return !specialWorkspaceIds.has(workspace.id)
    && !isSpecialWorkspaceName(workspace.name)
}

function toVisibleWorkspace(workspace: AstalHyprland.Workspace): VisibleWorkspace {
  return {
    id: workspace.id,
    isEmpty: workspace.clients.length === 0,
  }
}

export function fixedVisibleWorkspaces(
  hyprland: AstalHyprland.Hyprland,
  ids: Array<number>,
) {
  const workspaces = hyprland.workspaces

  return ids.map((id) => {
    const workspace = findWorkspaceById(hyprland, workspaces, id)

    return workspace
      ? toVisibleWorkspace(workspace)
      : { id, isEmpty: true }
  })
}

export function currentVisibleWorkspaces(
  hyprland: AstalHyprland.Hyprland,
  visibility: NormalizedWorkspaceVisibilityConfig,
) {
  const workspaces = hyprland.workspaces
  const specialWorkspaceIds = visibility.excludeSpecial
    ? activeSpecialWorkspaceIds(hyprland)
    : new Set<number>()
  const focusedWorkspace = hyprland.focusedWorkspace
  const alwaysVisible = visibility.alwaysShow
    .map((id) => findWorkspaceById(hyprland, workspaces, id))
    .filter((workspace): workspace is AstalHyprland.Workspace => workspace !== null)
    .map(toVisibleWorkspace)
  const focusedVisibleWorkspace = visibility.includeFocused
    && isVisibleWorkspaceCandidate(focusedWorkspace, specialWorkspaceIds, visibility.excludeSpecial)
    ? toVisibleWorkspace(focusedWorkspace)
    : undefined
  const occupiedVisibleWorkspaces = visibility.includeOccupied
    ? workspaces
      .filter((workspace) => workspace.clients.length > 0)
      .filter((workspace) => isVisibleWorkspaceCandidate(workspace, specialWorkspaceIds, visibility.excludeSpecial))
      .map(toVisibleWorkspace)
    : []

  return uniqueWorkspacesById([
    ...alwaysVisible,
    focusedVisibleWorkspace,
    ...occupiedVisibleWorkspaces,
  ].filter(Boolean) as Array<VisibleWorkspace>).sort(compareWorkspaceIds)
}
