import { createConnection } from "ags"
import AstalHyprland from "gi://AstalHyprland"
import { type BarOrientation } from "../../layout/placement"
import WorkspaceList from "./WorkspaceList"
import { currentVisibleWorkspaces, fixedVisibleWorkspaces } from "./workspaceVisibility"
import type { NormalizedWorkspaceVisibilityConfig } from "./types"

type DynamicProps = {
  orientation: BarOrientation
  mode: "dynamic"
  visibility: NormalizedWorkspaceVisibilityConfig
}

type FixedProps = {
  orientation: BarOrientation
  mode: "fixed"
  ids: Array<number>
}

type Props = DynamicProps | FixedProps

export default function WorkspacesWidget({ orientation, ...config }: Props) {
  const hyprland = AstalHyprland.get_default()

  const listVisibleWorkspaces = () => config.mode === "fixed"
    ? fixedVisibleWorkspaces(hyprland, config.ids)
    : currentVisibleWorkspaces(hyprland, config.visibility)

  const visibleWorkspaces = createConnection(
    listVisibleWorkspaces(),
    [hyprland, "notify::focused-workspace", listVisibleWorkspaces],
    [hyprland, "client-added", listVisibleWorkspaces],
    [hyprland, "client-removed", listVisibleWorkspaces],
    [hyprland, "client-moved", listVisibleWorkspaces],
  )

  return <WorkspaceList orientation={orientation} workspaces={visibleWorkspaces} />
}
