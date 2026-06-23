import PollingMonitorWidget, {
  type PollingMonitorFormat,
  type PollingMonitorDecimals,
} from "../shared/PollingMonitor.tsx"
import { mergeConfig, type WidgetClicks, type WidgetProps } from "../shared/types.ts"
import { createGpuState, formatGiB } from "./state.ts"

export type GpuConfig = {
  icon?: string
  card?: string
  format?: Partial<PollingMonitorFormat>
  decimals?: Partial<PollingMonitorDecimals>
  tooltip?: string
  interval?: number
  reveal?: { durationMs?: number }
  commands?: WidgetClicks
}

type GpuDefaults = {
  icon: string
  card: string
  format: PollingMonitorFormat
  decimals: PollingMonitorDecimals
  tooltip: string
  interval: number
  reveal: { durationMs: number }
  commands: WidgetClicks
}

export const defaults: GpuDefaults = {
  icon: "󰢮",
  card: "",
  format: { primary: "{usage}%", alt: "{usage}% | {vram_used}/{vram_total}", vertical: "{usage}%", verticalAlt: "{vram}%" },
  decimals: { primary: 0, alt: 0, vertical: 0, verticalAlt: 0 },
  tooltip: "{name}\nUsage: {usage}%\nVRAM: {vram_used}/{vram_total}\nTemp: {temp}°",
  interval: 5000,
  reveal: { durationMs: 200 },
  commands: {},
}

export default function Gpu({ config, placement }: WidgetProps<GpuConfig>) {
  const cfg = mergeConfig(defaults, config)
  const gpu = createGpuState(cfg.interval, cfg.card)

  function buildSubstitutions(d: number) {
    const usage = gpu.usage()
    const vramUsed = gpu.vramUsed()
    const vramTotal = gpu.vramTotal()
    const temp = gpu.temp()
    const vramFraction = vramUsed !== null && vramTotal !== null && vramTotal > 0 ? vramUsed / vramTotal : null
    return {
      usage: usage !== null ? (usage * 100).toFixed(d) : undefined,
      vram: vramFraction !== null ? (vramFraction * 100).toFixed(d) : undefined,
      vram_used: formatGiB(vramUsed),
      vram_total: formatGiB(vramTotal),
      temp: temp !== null ? temp.toFixed(d) : undefined,
      name: gpu.name() || undefined,
    }
  }

  return (
    <PollingMonitorWidget
      widgetClass="widget-gpu"
      orientation={placement.orientation}
      icon={cfg.icon}
      format={cfg.format}
      decimals={cfg.decimals}
      tooltip={cfg.tooltip}
      revealDurationMs={cfg.reveal.durationMs}
      commands={cfg.commands}
      buildSubstitutions={buildSubstitutions}
    />
  )
}
