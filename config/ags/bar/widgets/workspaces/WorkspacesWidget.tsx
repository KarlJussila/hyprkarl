import { createConnection } from "ags"
import AstalHyprland from "gi://AstalHyprland"
import { type NormalizedWorkspacesWidgetConfig } from "../../configuration"
import { type BarOrientation } from "../../layout/placement"
import WorkspaceList from "./WorkspaceList"
import { currentVisibleWorkspaces, fixedVisibleWorkspaces } from "./workspaceVisibility"

type Props = {
  orientation: BarOrientation
  config: NormalizedWorkspacesWidgetConfig
}

export default function WorkspacesWidget({ orientation, config }: Props) {
  const hyprland = AstalHyprland.get_default()

  const snapshotVisibleWorkspaces = () => config.mode === "fixed"
    ? fixedVisibleWorkspaces(hyprland, config.ids)
    : currentVisibleWorkspaces(hyprland, config.visibility)

  const visibleWorkspaceList = createConnection(
    snapshotVisibleWorkspaces(),
    [hyprland, "notify::focused-workspace", snapshotVisibleWorkspaces],
    [hyprland, "client-added", snapshotVisibleWorkspaces],
    [hyprland, "client-removed", snapshotVisibleWorkspaces],
    [hyprland, "client-moved", snapshotVisibleWorkspaces],
  )

  return <WorkspaceList orientation={orientation} workspaces={visibleWorkspaceList} />
}

