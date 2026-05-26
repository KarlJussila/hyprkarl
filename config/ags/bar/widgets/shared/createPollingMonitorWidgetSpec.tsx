import { createWidgetSpec } from "./widgetSpec.tsx"
import {
  normalizeDecimalsConfig,
  normalizeFormatConfig,
  normalizePositiveNumber,
  normalizeRevealConfig,
  normalizeSimpleTooltipConfig,
  normalizeStringValue,
  type NormalizedDecimalsConfig,
  type NormalizedFormatConfig,
  type NormalizedRevealConfig,
  type NormalizedSimpleTooltipConfig,
} from "./normalize.ts"
import { type BarOrientation } from "../../layout/placement.ts"

export type PollingMonitorComponentProps = {
  orientation: BarOrientation
  icon: string
  format: NormalizedFormatConfig
  decimals: NormalizedDecimalsConfig
  tooltip: NormalizedSimpleTooltipConfig
  interval: number
  revealDurationMs: number
}

type PollingMonitorDefaults = {
  icon: string
  format: NormalizedFormatConfig
  decimals: NormalizedDecimalsConfig
  tooltip: NormalizedSimpleTooltipConfig
  interval: number
  reveal: NormalizedRevealConfig
}

const pollingMonitorSchema = {
  icon: normalizeStringValue,
  format: normalizeFormatConfig,
  decimals: normalizeDecimalsConfig,
  tooltip: normalizeSimpleTooltipConfig,
  interval: normalizePositiveNumber,
  reveal: normalizeRevealConfig,
}

export function createPollingMonitorWidgetSpec<TKind extends string>({
  kind,
  defaults,
  Component,
}: {
  kind: TKind
  defaults: PollingMonitorDefaults
  Component: (props: PollingMonitorComponentProps) => JSX.Element
}) {
  return createWidgetSpec({
    kind,
    defaults,
    schema: pollingMonitorSchema,
    render: ({ config, placement }) => (
      <Component
        orientation={placement.orientation}
        icon={config.icon}
        format={config.format}
        decimals={config.decimals}
        tooltip={config.tooltip}
        interval={config.interval}
        revealDurationMs={config.reveal.durationMs}
      />
    ),
  })
}
