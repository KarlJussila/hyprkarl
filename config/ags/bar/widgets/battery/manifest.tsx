import BatteryWidget from "./BatteryWidget.tsx"
import { type WidgetManifest } from "../shared/widgetManifest.tsx"

const batteryManifest: WidgetManifest<"battery"> = {
  kind: "battery",
  render: ({ id, config, placement, monitor }) => (
    <BatteryWidget
      id={id}
      placement={placement}
      monitor={monitor}
      config={config}
    />
  ),
}

export default batteryManifest
