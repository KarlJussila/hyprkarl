import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  childContext,
  normalizeDecimalsConfig,
  normalizeFormatConfig,
  normalizePositiveNumber,
  normalizeRevealConfig,
  normalizeSimpleTooltipConfig,
  normalizeStringValue,
  widgetContext,
  type NormalizedDecimalsConfig,
  type NormalizedFormatConfig,
  type NormalizedRevealConfig,
  type NormalizedSimpleTooltipConfig,
  type SimpleTooltipConfig,
} from "../shared/normalize.ts"
import CpuWidget from "./CpuWidget.tsx"

const cpuDefaults = {
  icon: "󰍛",
  format: {
    primary: "",
    alt: "",
    vertical: "",
    verticalAlt: "",
  },
  decimals: {
    primary: 0,
    alt: 0,
    vertical: 0,
    verticalAlt: 0,
  },
  tooltip: {
    enabled: true,
    text: "CPU: {usage}%\n{cores}",
  },
  interval: 5000,
  reveal: {
    durationMs: 200,
  },
} satisfies {
  icon: string
  format: NormalizedFormatConfig
  decimals: NormalizedDecimalsConfig
  tooltip: NormalizedSimpleTooltipConfig
  interval: number
  reveal: NormalizedRevealConfig
}

type RawCpuConfig = {
  kind: "cpu"
  icon?: string
  format?: { primary?: string; alt?: string; vertical?: string; verticalAlt?: string }
  decimals?: { primary?: number; alt?: number; vertical?: number; verticalAlt?: number }
  tooltip?: SimpleTooltipConfig
  interval?: number
  reveal?: { durationMs?: number }
}

export default createWidgetSpec({
  kind: "cpu",
  defaults: cpuDefaults,
  resolve(id, definition: RawCpuConfig, defaults) {
    const ctx = widgetContext(id)
    const icon = normalizeStringValue(childContext(ctx, "icon"), definition.icon, defaults.icon)
    const format = normalizeFormatConfig(childContext(ctx, "format"), definition.format, defaults.format)
    const decimals = normalizeDecimalsConfig(childContext(ctx, "decimals"), definition.decimals, defaults.decimals)
    const tooltip = normalizeSimpleTooltipConfig(childContext(ctx, "tooltip"), definition.tooltip, defaults.tooltip)
    const interval = normalizePositiveNumber(childContext(ctx, "interval"), definition.interval, defaults.interval)
    const reveal = normalizeRevealConfig(childContext(ctx, "reveal"), definition.reveal, defaults.reveal)

    return {
      kind: "cpu" as const,
      icon,
      format,
      decimals,
      tooltip,
      interval,
      reveal,
    }
  },
  render: ({ config, placement }) => (
    <CpuWidget
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
