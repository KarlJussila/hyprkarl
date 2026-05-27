import { createConnection } from "ags"
import AstalHyprland from "gi://AstalHyprland"
import WorkspaceList from "./WorkspaceList.tsx"
import { currentVisibleWorkspaces, fixedVisibleWorkspaces } from "./workspaceVisibility.ts"
import type { WidgetRenderArgs } from "../shared/widgetSpec.tsx"
import type { NormalizedSimpleTooltipConfig } from "../shared/normalize.ts"
import type { NormalizedWorkspaceVisibilityConfig } from "./types.ts"

type Config =
  | {
      mode: "dynamic"
      visibility: NormalizedWorkspaceVisibilityConfig
      tooltip: NormalizedSimpleTooltipConfig
    }
  | {
      mode: "fixed"
      ids: Array<number>
      tooltip: NormalizedSimpleTooltipConfig
    }

export default function WorkspacesWidget({ config, placement }: WidgetRenderArgs<Config>) {
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

  return <WorkspaceList orientation={placement.orientation} workspaces={visibleWorkspaces} tooltip={config.tooltip} />
}
