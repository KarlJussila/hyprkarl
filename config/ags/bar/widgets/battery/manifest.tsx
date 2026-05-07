import BatteryWidget from "./BatteryWidget.tsx"
import { type WidgetManifest } from "../shared/widgetManifest.tsx"

const batteryManifest: WidgetManifest<"battery"> = {
  kind: "battery",
  render: ({ config, placement, monitor }) => (
    <BatteryWidget
      placement={placement}
      monitor={monitor}
      config={config}
    />
  ),
}

export default batteryManifest
