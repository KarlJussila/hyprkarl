import WorkspacesWidget from "./WorkspacesWidget.tsx"
import { type WidgetManifest } from "../shared/widgetManifest.tsx"

const workspacesManifest: WidgetManifest<"workspaces"> = {
  kind: "workspaces",
  render: ({ config, placement }) => (
    <WorkspacesWidget
      orientation={placement.orientation}
      config={config}
    />
  ),
}

export default workspacesManifest
