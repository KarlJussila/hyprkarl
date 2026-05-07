import TrayWidget from "./TrayWidget.tsx"
import { type WidgetManifest } from "../shared/widgetManifest.tsx"

const trayManifest: WidgetManifest<"tray"> = {
  kind: "tray",
  render: ({ config, placement }) => (
    <TrayWidget
      placement={placement}
      config={config}
    />
  ),
}

export default trayManifest
