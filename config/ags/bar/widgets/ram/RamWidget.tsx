import { type BarOrientation } from "../../layout/placement.ts"
import { createRamState } from "./ramState.ts"
import PollingMonitorWidget from "../shared/PollingMonitorWidget.tsx"
import type { NormalizedClickCommandsConfig, NormalizedDecimalsConfig, NormalizedFormatConfig, NormalizedSimpleTooltipConfig } from "../shared/normalize.ts"

type Props = {
  orientation: BarOrientation
  icon: string
  format: NormalizedFormatConfig
  decimals: NormalizedDecimalsConfig
  tooltip: NormalizedSimpleTooltipConfig
  interval: number
  revealDurationMs: number
  commands: NormalizedClickCommandsConfig
}

function formatPercent(fraction: number, decimals: number): string {
  return (fraction * 100).toFixed(decimals)
}

function formatSize(kb: number, decimals: number): string {
  if (kb >= 1024 * 1024) {
    return `${(kb / (1024 * 1024)).toFixed(decimals)}G`
  }
  return `${(kb / 1024).toFixed(decimals)}M`
}

export default function RamWidget({
  orientation,
  icon,
  format,
  decimals,
  tooltip,
  interval,
  revealDurationMs,
  commands,
}: Props) {
  const ram = createRamState(interval)

  function buildSubstitutions(d: number) {
    const ramFreeKb = ram.ramTotalKb() - ram.ramUsedKb()
    const swapFreeKb = ram.swapTotalKb() - ram.swapUsedKb()
    return {
      ram: formatPercent(ram.ramFraction(), d),
      ram_used: formatSize(ram.ramUsedKb(), d),
      ram_total: formatSize(ram.ramTotalKb(), d),
      ram_free: formatSize(ramFreeKb, d),
      swap: formatPercent(ram.swapFraction(), d),
      swap_used: formatSize(ram.swapUsedKb(), d),
      swap_total: formatSize(ram.swapTotalKb(), d),
      swap_free: formatSize(swapFreeKb, d),
    }
  }

  return (
    <PollingMonitorWidget
      widgetClass="widget-ram"
      orientation={orientation}
      icon={icon}
      format={format}
      decimals={decimals}
      tooltip={tooltip}
      revealDurationMs={revealDurationMs}
      commands={commands}
      buildSubstitutions={buildSubstitutions}
    />
  )
}
