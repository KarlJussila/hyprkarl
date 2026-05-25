import { createConnection } from "ags"
import AstalHyprland from "gi://AstalHyprland"
import { type BarOrientation } from "../../layout/placement"
import WorkspaceList from "./WorkspaceList"
import { currentVisibleWorkspaces, fixedVisibleWorkspaces } from "./workspaceVisibility"
import type { NormalizedSimpleTooltipConfig } from "../shared/normalize.ts"
import type { NormalizedWorkspaceVisibilityConfig } from "./types"

type DynamicProps = {
  orientation: BarOrientation
  mode: "dynamic"
  visibility: NormalizedWorkspaceVisibilityConfig
  tooltip: NormalizedSimpleTooltipConfig
}

type FixedProps = {
  orientation: BarOrientation
  mode: "fixed"
  ids: Array<number>
  tooltip: NormalizedSimpleTooltipConfig
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

  return <WorkspaceList orientation={orientation} workspaces={visibleWorkspaces} tooltip={config.tooltip} />
}
