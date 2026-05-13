import ClockWidget from "./ClockWidget.tsx"
import { type WidgetManifest } from "../shared/widgetManifest.tsx"

const clockManifest: WidgetManifest<"clock"> = {
  kind: "clock",
  render: ({ id, config, placement, monitor }) => (
    <ClockWidget
      id={id}
      placement={placement}
      monitor={monitor}
      config={config}
    />
  ),
}

export default clockManifest
