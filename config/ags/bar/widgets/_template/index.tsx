// Reference widget — copy this file to start a new widget type.
//
// Pattern:
// 1. Export a `Config` type with all fields optional.
// 2. Export a `defaults` const matching the resolved (all-fields-present) shape.
// 3. Default-export the component. Use `mergeConfig(defaults, config)` to fill in
//    any unspecified fields with defaults.
// 4. Register the kind in `bar/widgets/index.ts` and document it in `SPEC.md`.
import Button from "../../primitives/Button.tsx"
import { useWidgetCommands } from "../shared/useWidgetCommands.ts"
import { mergeConfig, type WidgetClicks, type WidgetProps } from "../shared/types.ts"

export type TemplateConfig = {
  label?: string
  active?: boolean
  icons?: Partial<{ active: string; inactive: string }>
  commands?: WidgetClicks
  tooltip?: string
}

type TemplateDefaults = {
  label: string
  active: boolean
  icons: { active: string; inactive: string }
  commands: WidgetClicks
  tooltip: string
}

export const defaults: TemplateDefaults = {
  label: "template",
  active: true,
  icons: { active: "*", inactive: "-" },
  commands: {},
  tooltip: "Template widget — copy bar/widgets/_template.tsx",
}

export default function Template({ config, placement }: WidgetProps<TemplateConfig>) {
  const cfg = mergeConfig(defaults, config)
  const { label, active, icons, commands, tooltip } = cfg
  const { execPrimary, execSecondary, execTertiary } = useWidgetCommands({ commands })

  return (
    <Button
      class="widget-template-button widget-glyph-button"
      orientation={placement.orientation}
      tooltipText={tooltip || undefined}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execTertiary={execTertiary}
    >
      <label class="widget-template-label" label={`${active ? icons.active : icons.inactive} ${label}`} />
    </Button>
  )
}
