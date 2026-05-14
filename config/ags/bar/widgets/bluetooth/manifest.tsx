import BluetoothWidget from "./BluetoothWidget.tsx"
import { type WidgetManifest } from "../shared/widgetManifest.tsx"

const bluetoothManifest: WidgetManifest<"bluetooth"> = {
  kind: "bluetooth",
  render: ({ config, placement }) => (
    <BluetoothWidget
      orientation={placement.orientation}
      config={config}
    />
  ),
}

export default bluetoothManifest
