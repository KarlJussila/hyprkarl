// Reference widget — copy this folder to start a new widget type.
//
// What this exercises:
// - createWidgetSpec with the schema overload
// - commonWidgetSchema/Defaults for the standard tooltip + click-commands surface
// - composeObject for a widget-specific nested config object
// - single-prop render pattern
//
// To use as-is, leave it registered in catalog.ts. To create a new widget,
// copy this folder, rename it and the `kind`, then register the new spec in
// catalog.ts.
import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  composeObject,
  normalizeBoolean,
  normalizeStringValue,
} from "../shared/normalize.ts"
import { commonWidgetSchema, commonWidgetDefaults } from "../shared/widgetKit.ts"
import TemplateWidget from "./TemplateWidget.tsx"

const normalizeIcons = composeObject({
  active: normalizeStringValue,
  inactive: normalizeStringValue,
})

export default createWidgetSpec({
  kind: "_template",
  defaults: {
    ...commonWidgetDefaults,
    label: "template",
    active: true,
    icons: { active: "*", inactive: "-" },
    tooltip: { text: "Template widget — copy bar/widgets/_template/" },
  },
  schema: {
    ...commonWidgetSchema,
    label: normalizeStringValue,
    active: normalizeBoolean,
    icons: normalizeIcons,
  },
  render: (args) => (
    <TemplateWidget {...args} />
  ),
})
