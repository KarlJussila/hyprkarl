import { createConnection } from "ags"
import AstalHyprland from "gi://AstalHyprland"
import WorkspaceList from "./List.tsx"
import { currentVisibleWorkspaces, fixedVisibleWorkspaces } from "./visibility.ts"
import type { WorkspaceVisibility } from "./types.ts"
import { type WidgetProps } from "../shared/types.ts"

export type WorkspacesConfig =
  | {
      mode?: "dynamic"
      visibility?: Partial<WorkspaceVisibility>
      tooltip?: string
    }
  | {
      mode: "fixed"
      ids: Array<number>
      tooltip?: string
    }

const visibilityDefaults: WorkspaceVisibility = {
  alwaysShow: [1],
  includeFocused: true,
  includeOccupied: true,
  excludeSpecial: true,
}

export const defaults = {
  mode: "dynamic" as const,
  visibility: visibilityDefaults,
  tooltip: "",
}

export default function WorkspacesWidget({ config, placement }: WidgetProps<WorkspacesConfig>) {
  const hyprland = AstalHyprland.get_default()
  const tooltip = config.tooltip ?? defaults.tooltip
  const mode = config.mode ?? defaults.mode

  const listVisibleWorkspaces = () => {
    if (mode === "fixed") {
      const ids = (config as { mode: "fixed"; ids: Array<number> }).ids
      if (!Array.isArray(ids) || ids.length === 0) {
        throw new Error(`workspaces widget in "fixed" mode requires a non-empty ids array`)
      }
      return fixedVisibleWorkspaces(hyprland, ids)
    }
    const userVisibility = (config as { visibility?: Partial<WorkspaceVisibility> }).visibility
    const visibility = userVisibility
      ? { ...visibilityDefaults, ...userVisibility }
      : visibilityDefaults
    return currentVisibleWorkspaces(hyprland, visibility)
  }

  const visibleWorkspaces = createConnection(
    listVisibleWorkspaces(),
    [hyprland, "notify::focused-workspace", listVisibleWorkspaces],
    [hyprland, "client-added", listVisibleWorkspaces],
    [hyprland, "client-removed", listVisibleWorkspaces],
    [hyprland, "client-moved", listVisibleWorkspaces],
  )

  return <WorkspaceList orientation={placement.orientation} workspaces={visibleWorkspaces} tooltip={tooltip} />
}
