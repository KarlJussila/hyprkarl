import type {
  NormalizedWorkspacesWidgetConfig,
  WidgetDefinitionByKind,
} from "../../configuration.ts"
import {
  fail,
  normalizeIntegerList,
  normalizeVisibility,
  widgetContext,
} from "../shared/normalize.ts"

type DynamicWorkspaceConfig = Extract<NormalizedWorkspacesWidgetConfig, { mode: "dynamic" }>

const workspacesDefaults: Omit<DynamicWorkspaceConfig, "kind"> = {
  mode: "dynamic",
  visibility: {
    alwaysShow: [1],
    includeFocused: true,
    includeOccupied: true,
    excludeSpecial: true,
  },
}

function validateWorkspaceMode(id: string, value: unknown) {
  if (value === undefined || value === "dynamic" || value === "fixed") {
    return
  }

  fail(widgetContext(id, "mode"), 'must be "dynamic" or "fixed"')
}

export function normalizeWorkspacesWidgetConfig(
  id: string,
  definition: WidgetDefinitionByKind["workspaces"],
): NormalizedWorkspacesWidgetConfig {
  validateWorkspaceMode(id, definition.mode)

  if (definition.mode === "fixed") {
    return {
      kind: "workspaces",
      mode: "fixed",
      ids: normalizeIntegerList(
        widgetContext(id, "ids"),
        definition.ids,
        false,
      ),
    }
  }

  return {
    kind: "workspaces",
    mode: "dynamic",
    visibility: normalizeVisibility(
      id,
      definition.visibility,
      workspacesDefaults.visibility,
    ),
  }
}

