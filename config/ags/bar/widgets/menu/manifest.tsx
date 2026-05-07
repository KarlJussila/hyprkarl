import MenuWidget from "./MenuWidget.tsx"
import { type WidgetManifest } from "../shared/widgetManifest.tsx"

const menuManifest: WidgetManifest<"menu"> = {
  kind: "menu",
  render: ({ config, placement }) => (
    <MenuWidget
      orientation={placement.orientation}
      config={config}
    />
  ),
}

export default menuManifest
