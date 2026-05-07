import CaffeineWidget from "./CaffeineWidget.tsx"
import { type WidgetManifest } from "../shared/widgetManifest.tsx"

const caffeineManifest: WidgetManifest<"caffeine"> = {
  kind: "caffeine",
  render: ({ config, placement }) => (
    <CaffeineWidget
      orientation={placement.orientation}
      config={config}
    />
  ),
}

export default caffeineManifest
