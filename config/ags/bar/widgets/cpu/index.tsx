import { createPoll } from "ags/time"
import { readFile } from "ags/file"
import PollingMonitorWidget, {
  type PollingMonitorFormat,
  type PollingMonitorDecimals,
} from "../shared/PollingMonitor.tsx"
import { mergeConfig, type WidgetClicks, type WidgetProps } from "../shared/types.ts"

export type CpuConfig = {
  icon?: string
  format?: Partial<PollingMonitorFormat>
  decimals?: Partial<PollingMonitorDecimals>
  tooltip?: string
  interval?: number
  reveal?: { durationMs?: number }
  commands?: WidgetClicks
}

type CpuDefaults = {
  icon: string
  format: PollingMonitorFormat
  decimals: PollingMonitorDecimals
  tooltip: string
  interval: number
  reveal: { durationMs: number }
  commands: WidgetClicks
}

export const defaults: CpuDefaults = {
  icon: "󰍛",
  format: { primary: "", alt: "", vertical: "", verticalAlt: "" },
  decimals: { primary: 0, alt: 0, vertical: 0, verticalAlt: 0 },
  tooltip: "CPU: {usage}%\n{cores}",
  interval: 5000,
  reveal: { durationMs: 200 },
  commands: {},
}

type CpuSample = { idle: number; total: number }
type CpuSamples = { aggregate: CpuSample; cores: CpuSample[] }
type CpuPollState = { usage: number; coreUsages: number[]; prevSamples: CpuSamples; temp: number | null }

function parseCpuLine(line: string): CpuSample {
  const parts = line.trim().split(/\s+/).slice(1).map(Number)
  const [user = 0, nice = 0, system = 0, idle = 0, iowait = 0, irq = 0, softirq = 0, steal = 0] = parts
  const idleTime = idle + iowait
  const total = user + nice + system + idleTime + irq + softirq + steal
  return { idle: idleTime, total }
}

function readAllCpuSamples(): CpuSamples {
  try {
    const stat = readFile("/proc/stat")
    const lines = stat.split("\n").filter((l) => /^cpu\d*\s/.test(l))
    const [aggregateLine, ...coreLines] = lines
    return {
      aggregate: parseCpuLine(aggregateLine ?? ""),
      cores: coreLines.map(parseCpuLine),
    }
  } catch {
    return { aggregate: { idle: 0, total: 0 }, cores: [] }
  }
}

function computeUsage(curr: CpuSample, prev: CpuSample): number {
  const idleDelta = curr.idle - prev.idle
  const totalDelta = curr.total - prev.total
  return totalDelta > 0 ? Math.max(0, Math.min(1, 1 - idleDelta / totalDelta)) : 0
}

// Resolved once at module load — hwmon numbers are stable for the session.
function findCpuTempFile(): string | null {
  for (let i = 0; i < 16; i++) {
    try {
      const name = readFile(`/sys/class/hwmon/hwmon${i}/name`).trim()
      if (name !== "k10temp" && name !== "coretemp") continue
      const dir = `/sys/class/hwmon/hwmon${i}`
      // Prefer Tdie (temp2) over Tctl (temp1) on modern AMD k10temp.
      try {
        if (readFile(`${dir}/temp2_label`).trim() === "Tdie") return `${dir}/temp2_input`
      } catch {}
      return `${dir}/temp1_input`
    } catch {
      continue
    }
  }
  return null
}

const cpuTempFile = findCpuTempFile()

function readCpuTemp(): number | null {
  if (!cpuTempFile) return null
  try {
    return parseInt(readFile(cpuTempFile).trim(), 10) / 1000
  } catch {
    return null
  }
}

function createCpuState(intervalMs: number) {
  const initialSamples = readAllCpuSamples()

  const state = createPoll<CpuPollState>(
    { usage: 0, coreUsages: initialSamples.cores.map(() => 0), prevSamples: initialSamples, temp: readCpuTemp() },
    intervalMs,
    (prev) => {
      const curr = readAllCpuSamples()
      const usage = computeUsage(curr.aggregate, prev.prevSamples.aggregate)
      const coreUsages = curr.cores.map((sample, i) =>
        computeUsage(sample, prev.prevSamples.cores[i] ?? sample),
      )
      return { usage, coreUsages, prevSamples: curr, temp: readCpuTemp() }
    },
  )

  return {
    usage: state((s) => s.usage),
    coreUsages: state((s) => s.coreUsages),
    temp: state((s) => s.temp),
  }
}

export default function Cpu({ config, placement }: WidgetProps<CpuConfig>) {
  const cfg = mergeConfig(defaults, config)
  const cpu = createCpuState(cfg.interval)

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
