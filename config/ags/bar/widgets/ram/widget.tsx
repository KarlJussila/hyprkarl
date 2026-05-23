import { createWidgetSpec } from "../shared/widgetSpec.tsx"
import {
  normalizePositiveNumber,
  normalizeNonNegativeNumber,
  normalizeStringValue,
  widgetContext,
  childContext,
} from "../shared/normalize.ts"
import RamWidget from "./RamWidget.tsx"

const ramDefaults = {
  icon: "",
  format: "{ram}%",
  formatAlt: "{ram_used}/{ram_total} | {swap_used}/{swap_total}",
  formatVertical: "{ram}%",
  formatVerticalAlt: "{ram_used}\n{swap_used}",
  decimals: 0,
  tooltip: "RAM: {ram_used}/{ram_total}\nSwap: {swap_used}/{swap_total}",
  interval: 5000,
}

type RawRamConfig = {
  kind: "ram"
  icon?: string
  format?: string
  formatAlt?: string
  formatVertical?: string
  formatVerticalAlt?: string
  decimals?: number
  decimalsAlt?: number
  decimalsVertical?: number
  decimalsVerticalAlt?: number
  tooltip?: string
  interval?: number
}

export default createWidgetSpec({
  kind: "ram",
  defaults: ramDefaults,
  resolve(id, definition: RawRamConfig, defaults) {
    const ctx = widgetContext(id)
    const icon = normalizeStringValue(childContext(ctx, "icon"), definition.icon, defaults.icon)
    const format = normalizeStringValue(childContext(ctx, "format"), definition.format, defaults.format)
    const formatAlt = normalizeStringValue(childContext(ctx, "formatAlt"), definition.formatAlt, defaults.formatAlt)
    const formatVertical = normalizeStringValue(childContext(ctx, "formatVertical"), definition.formatVertical, defaults.formatVertical)
    const formatVerticalAlt = normalizeStringValue(childContext(ctx, "formatVerticalAlt"), definition.formatVerticalAlt, defaults.formatVerticalAlt)
    const tooltip = normalizeStringValue(childContext(ctx, "tooltip"), definition.tooltip, defaults.tooltip)
    const interval = normalizePositiveNumber(childContext(ctx, "interval"), definition.interval, defaults.interval)

    const decimals = normalizeNonNegativeNumber(childContext(ctx, "decimals"), definition.decimals, defaults.decimals)
    const decimalsAlt = normalizeNonNegativeNumber(childContext(ctx, "decimalsAlt"), definition.decimalsAlt, decimals)
    const decimalsVertical = normalizeNonNegativeNumber(childContext(ctx, "decimalsVertical"), definition.decimalsVertical, decimals)
    const decimalsVerticalAlt = normalizeNonNegativeNumber(childContext(ctx, "decimalsVerticalAlt"), definition.decimalsVerticalAlt, decimalsVertical)

    return {
      kind: "ram" as const,
      icon,
      format,
      formatAlt,
      formatVertical,
      formatVerticalAlt,
      decimals,
      decimalsAlt,
      decimalsVertical,
      decimalsVerticalAlt,
      tooltip,
      interval,
    }
  },
  render: ({ config, placement }) => (
    <RamWidget
      orientation={placement.orientation}
      icon={config.icon}
      format={config.format}
      formatAlt={config.formatAlt}
      formatVertical={config.formatVertical}
      formatVerticalAlt={config.formatVerticalAlt}
      decimals={config.decimals}
      decimalsAlt={config.decimalsAlt}
      decimalsVertical={config.decimalsVertical}
      decimalsVerticalAlt={config.decimalsVerticalAlt}
      tooltip={config.tooltip}
      interval={config.interval}
    />
  ),
})
