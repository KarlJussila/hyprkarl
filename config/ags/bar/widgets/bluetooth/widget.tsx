import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizeRequiredCommand } from "../shared/normalize.ts"
import BluetoothWidget from "./BluetoothWidget.tsx"

export default createWidgetSpec({
  kind: "bluetooth",
  defaults: {
    command: "hk-launch-bluetooth",
  },
  schema: {
    command: normalizeRequiredCommand,
  },
  render: ({ config, placement }) => (
    <BluetoothWidget orientation={placement.orientation} command={config.command} />
  ),
})
