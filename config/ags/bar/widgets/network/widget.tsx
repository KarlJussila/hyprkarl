import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import { normalizeRequiredCommand } from "../shared/normalize.ts"
import NetworkWidget from "./NetworkWidget.tsx"

export default createWidgetSpec({
  kind: "network",
  defaults: {
    command: "hk-launch-wifi",
  },
  schema: {
    command: normalizeRequiredCommand,
  },
  render: ({ config, placement }) => (
    <NetworkWidget orientation={placement.orientation} command={config.command} />
  ),
})
