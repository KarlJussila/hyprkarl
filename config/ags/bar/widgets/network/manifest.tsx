import NetworkWidget from "./NetworkWidget.tsx"
import { type WidgetManifest } from "../shared/widgetManifest.tsx"

const networkManifest: WidgetManifest<"network"> = {
  kind: "network",
  render: ({ config, placement }) => (
    <NetworkWidget
      orientation={placement.orientation}
      config={config}
    />
  ),
}

export default networkManifest
