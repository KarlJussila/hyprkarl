import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  composeObject,
  normalizeOptionalCommand,
  normalizeRequiredCommand,
  normalizeSimpleTooltipConfig,
  normalizeStringValue,
} from "../shared/normalize.ts"
import MenuWidget from "./MenuWidget.tsx"

export const normalizeMenuCommands = composeObject({
  primary: normalizeRequiredCommand,
  secondary: normalizeOptionalCommand,
  tertiary: normalizeOptionalCommand,
})

export default createWidgetSpec({
  kind: "menu",
  defaults: {
    icon: "",
    commands: { primary: "hk-menu", secondary: undefined, tertiary: undefined },
    tooltip: { text: "" },
  },
  schema: {
    icon: normalizeStringValue,
    commands: normalizeMenuCommands,
    tooltip: normalizeSimpleTooltipConfig,
  },
  render: (args) => (
    <MenuWidget {...args} />
  ),
})
