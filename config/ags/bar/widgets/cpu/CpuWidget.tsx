import { type BarOrientation } from "../../layout/placement.ts"
import { createCpuState } from "./cpuState.ts"
import PollingMonitorWidget from "../shared/PollingMonitorWidget.tsx"
import type { NormalizedDecimalsConfig, NormalizedFormatConfig, NormalizedSimpleTooltipConfig } from "../shared/normalize.ts"

type Props = {
  orientation: BarOrientation
  icon: string
  format: NormalizedFormatConfig
  decimals: NormalizedDecimalsConfig
  tooltip: NormalizedSimpleTooltipConfig
  interval: number
  revealDurationMs: number
}

export default function CpuWidget({ orientation, icon, format, decimals, tooltip, interval, revealDurationMs }: Props) {
  const cpu = createCpuState(interval)

  function buildSubstitutions(d: number) {
    const tempVal = cpu.temp()
    const coreLines = cpu.coreUsages().map((u, i) => `Core ${i}: ${(u * 100).toFixed(d)}%`)
    return {
      usage: (cpu.usage() * 100).toFixed(d),
      temp: tempVal !== null ? tempVal.toFixed(d) : undefined,
      cores: coreLines.join("\n"),
    }
  }

  return (
    <PollingMonitorWidget
      widgetClass="widget-cpu"
      orientation={orientation}
      icon={icon}
      format={format}
      decimals={decimals}
      tooltip={tooltip}
      revealDurationMs={revealDurationMs}
      buildSubstitutions={buildSubstitutions}
    />
  )
}
