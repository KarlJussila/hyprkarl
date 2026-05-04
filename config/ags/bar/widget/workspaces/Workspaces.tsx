import { createConnection } from "ags"
import AstalHyprland from "gi://AstalHyprland"
import { type BarOrientation } from "../../barPlacement"
import WorkspaceList from "./WorkspaceList"
import { currentVisibleWorkspaces, type VisibleWorkspace } from "./workspaceVisibility"

type Props = {
  orientation: BarOrientation
  workspaceIds?: Array<number>
}

function FixedWorkspaceList({
  orientation,
  workspaceIds,
}: {
  orientation: BarOrientation
  workspaceIds: Array<number>
}) {
  const workspaces: Array<VisibleWorkspace> = workspaceIds.map((id) => ({
    id,
    isEmpty: false,
  }))

  return <WorkspaceList orientation={orientation} workspaces={workspaces} />
}

function DynamicWorkspaceList({ orientation }: { orientation: BarOrientation }) {
  const hyprland = AstalHyprland.get_default()
  const visibleWorkspaceList = createConnection(
    currentVisibleWorkspaces(hyprland),
    [hyprland, "notify::focused-workspace", () => currentVisibleWorkspaces(hyprland)],
    [hyprland, "client-added", () => currentVisibleWorkspaces(hyprland)],
    [hyprland, "client-removed", () => currentVisibleWorkspaces(hyprland)],
    [hyprland, "client-moved", () => currentVisibleWorkspaces(hyprland)],
  )

  return <WorkspaceList orientation={orientation} workspaces={visibleWorkspaceList} />
}

export default function Workspaces({ orientation, workspaceIds }: Props) {
  if (workspaceIds && workspaceIds.length > 0) {
    return <FixedWorkspaceList orientation={orientation} workspaceIds={workspaceIds} />
  }

  return <DynamicWorkspaceList orientation={orientation} />
}
