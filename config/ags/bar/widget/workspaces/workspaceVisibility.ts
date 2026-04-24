import AstalHyprland from "gi://AstalHyprland"

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

function isVisibleWorkspaceCandidate(
  workspace: AstalHyprland.Workspace | null | undefined,
  specialWorkspaceIds: Set<number>,
) {
  if (!workspace) return false

  return !specialWorkspaceIds.has(workspace.id)
    && !isSpecialWorkspaceName(workspace.name)
}

function toVisibleWorkspace(workspace: AstalHyprland.Workspace): VisibleWorkspace {
  return {
    id: workspace.id,
    isEmpty: workspace.clients.length === 0,
  }
}

function workspaceOne(
  hyprland: AstalHyprland.Hyprland,
  workspaces: Array<AstalHyprland.Workspace>,
) {
  return workspaces.find((workspace) => workspace.id === 1) ?? hyprland.get_workspace(1)
}

function occupiedVisibleWorkspaces(
  workspaces: Array<AstalHyprland.Workspace>,
  specialWorkspaceIds: Set<number>,
) {
  return workspaces
    .filter((workspace) => workspace.id !== 1)
    .filter((workspace) => isVisibleWorkspaceCandidate(workspace, specialWorkspaceIds))
    .filter((workspace) => workspace.clients.length > 0)
    .map(toVisibleWorkspace)
}

export function currentVisibleWorkspaces(hyprland: AstalHyprland.Hyprland) {
  const workspaces = hyprland.workspaces
  const specialWorkspaceIds = activeSpecialWorkspaceIds(hyprland)
  const firstWorkspace = workspaceOne(hyprland, workspaces)
  const focusedWorkspace = hyprland.focusedWorkspace
  const visibleWorkspaces = occupiedVisibleWorkspaces(workspaces, specialWorkspaceIds)
  const focusedVisibleWorkspace = isVisibleWorkspaceCandidate(focusedWorkspace, specialWorkspaceIds)
    ? toVisibleWorkspace(focusedWorkspace)
    : undefined

  return uniqueWorkspacesById([
    firstWorkspace ? toVisibleWorkspace(firstWorkspace) : { id: 1, isEmpty: true },
    focusedVisibleWorkspace,
    ...visibleWorkspaces,
  ].filter(Boolean) as Array<VisibleWorkspace>).sort(compareWorkspaceIds)
}
