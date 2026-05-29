import { createPoll } from "ags/time"
import { readFile } from "ags/file"
import PollingMonitorWidget, {
  type PollingMonitorFormat,
  type PollingMonitorDecimals,
} from "../shared/PollingMonitor.tsx"
import { mergeConfig, type WidgetClicks, type WidgetProps } from "../shared/types.ts"

export type RamConfig = {
  icon?: string
  format?: Partial<PollingMonitorFormat>
  decimals?: Partial<PollingMonitorDecimals>
  tooltip?: string
  interval?: number
  reveal?: { durationMs?: number }
  commands?: WidgetClicks
}

type RamDefaults = {
  icon: string
  format: PollingMonitorFormat
  decimals: PollingMonitorDecimals
  tooltip: string
  interval: number
  reveal: { durationMs: number }
  commands: WidgetClicks
}

export const defaults: RamDefaults = {
  icon: "",
  format: {
    primary: "{ram}%",
    alt: "{ram_used}/{ram_total} | {swap_used}/{swap_total}",
    vertical: "{ram}%",
    verticalAlt: "{ram_used}\n{swap_used}",
  },
  decimals: { primary: 0, alt: 0, vertical: 0, verticalAlt: 0 },
  tooltip: "RAM: {ram_used}/{ram_total}\nSwap: {swap_used}/{swap_total}",
  interval: 5000,
  reveal: { durationMs: 200 },
  commands: {},
}

type MemInfo = {
  total: number
  available: number
  swapTotal: number
  swapFree: number
}

type RamState = {
  ramFraction: number
  ramUsedKb: number
  ramTotalKb: number
  swapFraction: number
  swapUsedKb: number
  swapTotalKb: number
}

function parseMemInfo(): MemInfo {
  try {
    const content = readFile("/proc/meminfo")
    const get = (key: string): number => {
      const match = content.match(new RegExp(`^${key}:\\s+(\\d+)`, "m"))
      return match ? parseInt(match[1]!, 10) : 0
    }
    return {
      total: get("MemTotal"),
      available: get("MemAvailable"),
      swapTotal: get("SwapTotal"),
      swapFree: get("SwapFree"),
    }
  } catch {
    return { total: 0, available: 0, swapTotal: 0, swapFree: 0 }
  }
}

function computeState(info: MemInfo): RamState {
  const ramUsedKb = Math.max(0, info.total - info.available)
  const swapUsedKb = Math.max(0, info.swapTotal - info.swapFree)
  return {
    ramFraction: info.total > 0 ? ramUsedKb / info.total : 0,
    ramUsedKb,
    ramTotalKb: info.total,
    swapFraction: info.swapTotal > 0 ? swapUsedKb / info.swapTotal : 0,
    swapUsedKb,
    swapTotalKb: info.swapTotal,
  }
}

function createRamState(intervalMs: number) {
  const state = createPoll<RamState>(computeState(parseMemInfo()), intervalMs, () =>
    computeState(parseMemInfo()),
  )

  return {
    ramFraction: state((s) => s.ramFraction),
    ramUsedKb: state((s) => s.ramUsedKb),
    ramTotalKb: state((s) => s.ramTotalKb),
    swapFraction: state((s) => s.swapFraction),
    swapUsedKb: state((s) => s.swapUsedKb),
    swapTotalKb: state((s) => s.swapTotalKb),
  }
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

export default function Ram({ config, placement }: WidgetProps<RamConfig>) {
  const cfg = mergeConfig(defaults, config)
  const ram = createRamState(cfg.interval)

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
