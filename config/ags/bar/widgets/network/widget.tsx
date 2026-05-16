import {
  createWidgetSpec,
  type WidgetConfig,
} from "../shared/widgetSpec.tsx"
import {
  normalizeRequiredCommand,
  widgetContext,
} from "../shared/normalize.ts"
import NetworkWidget from "./NetworkWidget.tsx"

export type NetworkWidgetConfig = WidgetConfig<"network", {
  command?: string
}>

const networkDefaults = {
  command: "hk-launch-wifi",
}

export default createWidgetSpec({
  kind: "network",
  defaults: networkDefaults,
  resolve(
    id: string,
    definition: NetworkWidgetConfig,
    defaults,
  ) {
    return {
      kind: "network",
      command: normalizeRequiredCommand(
        widgetContext(id, "command"),
        definition.command,
        defaults.command,
      ),
    }
  },
  render: ({ config, placement }) => (
    <NetworkWidget
      orientation={placement.orientation}
      command={config.command}
    />
  ),
})
