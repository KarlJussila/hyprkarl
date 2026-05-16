import {
  createWidgetSpec,
  type WidgetConfig,
} from "../shared/widgetSpec.tsx"
import {
  normalizeRequiredCommand,
  widgetContext,
} from "../shared/normalize.ts"
import BluetoothWidget from "./BluetoothWidget.tsx"

export type BluetoothWidgetConfig = WidgetConfig<"bluetooth", {
  command?: string
}>

const bluetoothDefaults = {
  command: "hk-launch-bluetooth",
}

export default createWidgetSpec({
  kind: "bluetooth",
  defaults: bluetoothDefaults,
  resolve(
    id: string,
    definition: BluetoothWidgetConfig,
    defaults,
  ) {
    return {
      kind: "bluetooth",
      command: normalizeRequiredCommand(
        widgetContext(id, "command"),
        definition.command,
        defaults.command,
      ),
    }
  },
  render: ({ config, placement }) => (
    <BluetoothWidget
      orientation={placement.orientation}
      command={config.command}
    />
  ),
})
