import {
  createWidgetSpec,
  type WidgetConfig,
} from "../shared/widgetSpec.tsx"
import {
  fail,
  normalizeIntegerList,
  normalizeSimpleTooltipConfig,
  widgetContext,
  type NormalizedSimpleTooltipConfig,
  type SimpleTooltipConfig,
} from "../shared/normalize.ts"
import { normalizeVisibility } from "./normalize.ts"
import type {
  NormalizedWorkspaceVisibilityConfig,
  WorkspaceVisibilityConfig,
} from "./types.ts"
import WorkspacesWidget from "./WorkspacesWidget.tsx"

export type WorkspacesWidgetConfig =
  | WidgetConfig<"workspaces", {
      mode?: "dynamic"
      visibility?: WorkspaceVisibilityConfig
      tooltip?: SimpleTooltipConfig
    }>
  | WidgetConfig<"workspaces", {
      mode: "fixed"
      ids: Array<number>
      tooltip?: SimpleTooltipConfig
    }>

type DynamicWorkspaceConfig = {
  kind: "workspaces"
  mode: "dynamic"
  visibility: NormalizedWorkspaceVisibilityConfig
  tooltip: NormalizedSimpleTooltipConfig
}

type FixedWorkspaceConfig = {
  kind: "workspaces"
  mode: "fixed"
  ids: Array<number>
  tooltip: NormalizedSimpleTooltipConfig
}

type WorkspacesResolvedConfig = DynamicWorkspaceConfig | FixedWorkspaceConfig

const workspacesDefaults = {
  mode: "dynamic",
  visibility: {
    alwaysShow: [1],
    includeFocused: true,
    includeOccupied: true,
    excludeSpecial: true,
  },
  tooltip: {
    enabled: true,
    text: "",
  },
} satisfies Omit<DynamicWorkspaceConfig, "kind">

function validateWorkspaceMode(id: string, value: unknown) {
  if (value === undefined || value === "dynamic" || value === "fixed") {
    return
  }

  fail(widgetContext(id, "mode"), 'must be "dynamic" or "fixed"')
}

export default createWidgetSpec({
  kind: "workspaces",
  defaults: workspacesDefaults,
  resolve(
    id: string,
    definition: WorkspacesWidgetConfig,
    defaults,
  ): WorkspacesResolvedConfig {
    validateWorkspaceMode(id, definition.mode)

    const tooltip = normalizeSimpleTooltipConfig(
      widgetContext(id, "tooltip"),
      definition.tooltip,
      defaults.tooltip,
    )

    if (definition.mode === "fixed") {
      return {
        kind: "workspaces",
        mode: "fixed",
        ids: normalizeIntegerList(
          widgetContext(id, "ids"),
          definition.ids,
          false,
        ),
        tooltip,
      }
    }

    return {
      kind: "workspaces",
      mode: "dynamic",
      visibility: normalizeVisibility(
        widgetContext(id, "visibility"),
        definition.visibility,
        defaults.visibility,
      ),
      tooltip,
    }
  },
  render: ({ config, placement }) => (
    <WorkspacesWidget
      orientation={placement.orientation}
      {...config}
    />
  ),
})
