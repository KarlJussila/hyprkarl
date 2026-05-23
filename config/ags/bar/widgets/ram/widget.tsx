import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  childContext,
  normalizeDecimalsConfig,
  normalizeFormatConfig,
  normalizePositiveNumber,
  normalizeRevealConfig,
  normalizeStringValue,
  widgetContext,
  type NormalizedDecimalsConfig,
  type NormalizedFormatConfig,
  type NormalizedRevealConfig,
} from "../shared/normalize.ts"
import RamWidget from "./RamWidget.tsx"

const ramDefaults = {
  icon: "",
  format: {
    primary: "{ram}%",
    alt: "{ram_used}/{ram_total} | {swap_used}/{swap_total}",
    vertical: "{ram}%",
    verticalAlt: "{ram_used}\n{swap_used}",
  },
  decimals: {
    primary: 0,
    alt: 0,
    vertical: 0,
    verticalAlt: 0,
  },
  tooltip: "RAM: {ram_used}/{ram_total}\nSwap: {swap_used}/{swap_total}",
  interval: 5000,
  reveal: {
    durationMs: 200,
  },
} satisfies {
  icon: string
  format: NormalizedFormatConfig
  decimals: NormalizedDecimalsConfig
  tooltip: string
  interval: number
  reveal: NormalizedRevealConfig
}

type RawRamConfig = {
  kind: "ram"
  icon?: string
  format?: { primary?: string; alt?: string; vertical?: string; verticalAlt?: string }
  decimals?: { primary?: number; alt?: number; vertical?: number; verticalAlt?: number }
  tooltip?: string
  interval?: number
  reveal?: { durationMs?: number }
}

export default createWidgetSpec({
  kind: "ram",
  defaults: ramDefaults,
  resolve(id, definition: RawRamConfig, defaults) {
    const ctx = widgetContext(id)
    const icon = normalizeStringValue(childContext(ctx, "icon"), definition.icon, defaults.icon)
    const format = normalizeFormatConfig(childContext(ctx, "format"), definition.format, defaults.format)
    const decimals = normalizeDecimalsConfig(childContext(ctx, "decimals"), definition.decimals, defaults.decimals)
    const tooltip = normalizeStringValue(childContext(ctx, "tooltip"), definition.tooltip, defaults.tooltip)
    const interval = normalizePositiveNumber(childContext(ctx, "interval"), definition.interval, defaults.interval)
    const reveal = normalizeRevealConfig(childContext(ctx, "reveal"), definition.reveal, defaults.reveal)

    return {
      kind: "ram" as const,
      icon,
      format,
      decimals,
      tooltip,
      interval,
      reveal,
    }
  },
  render: ({ config, placement }) => (
    <RamWidget
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
