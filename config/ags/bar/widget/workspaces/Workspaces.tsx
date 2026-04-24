import { createConnection } from "ags"
import AstalHyprland from "gi://AstalHyprland"
import WorkspaceList from "./WorkspaceList"
import { currentVisibleWorkspaces, type VisibleWorkspace } from "./workspaceVisibility"

type Props = {
  workspaceIds?: Array<number>
}

function FixedWorkspaceList({ workspaceIds }: { workspaceIds: Array<number> }) {
  const workspaces: Array<VisibleWorkspace> = workspaceIds.map((id) => ({
    id,
    isEmpty: false,
  }))

  return <WorkspaceList workspaces={workspaces} />
}

function DynamicWorkspaceList() {
  const hyprland = AstalHyprland.get_default()
  const visibleWorkspaceList = createConnection(
    currentVisibleWorkspaces(hyprland),
    [hyprland, "notify::focused-workspace", () => currentVisibleWorkspaces(hyprland)],
    [hyprland, "client-added", () => currentVisibleWorkspaces(hyprland)],
    [hyprland, "client-removed", () => currentVisibleWorkspaces(hyprland)],
    [hyprland, "client-moved", () => currentVisibleWorkspaces(hyprland)],
  )

  return <WorkspaceList workspaces={visibleWorkspaceList} />
}

export default function Workspaces({ workspaceIds }: Props) {
  if (workspaceIds && workspaceIds.length > 0) {
    return <FixedWorkspaceList workspaceIds={workspaceIds} />
  }

  return <DynamicWorkspaceList />
}
