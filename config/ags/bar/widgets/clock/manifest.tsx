import ClockWidget from "./ClockWidget.tsx"
import { type WidgetManifest } from "../shared/widgetManifest.tsx"

const clockManifest: WidgetManifest<"clock"> = {
  kind: "clock",
  render: ({ config, placement, monitor }) => (
    <ClockWidget
      placement={placement}
      monitor={monitor}
      config={config}
    />
  ),
}

export default clockManifest
