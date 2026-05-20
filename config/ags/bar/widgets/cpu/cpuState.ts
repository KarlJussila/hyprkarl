import { createPoll } from "ags/time"
import { readFile } from "ags/file"
import { execAsync } from "ags/process"

type CpuSample = { idle: number; total: number }
type CpuSamples = { aggregate: CpuSample; cores: CpuSample[] }
type CpuPollState = { usage: number; coreUsages: number[]; prevSamples: CpuSamples }

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

function parseCpuTemp(jsonStr: string): number | null {
  try {
    const data = JSON.parse(jsonStr) as Record<string, unknown>
    const cpuKey = Object.keys(data).find((k) => k.startsWith("k10temp") || k.startsWith("coretemp"))
    if (!cpuKey) return null
    const device = data[cpuKey] as Record<string, unknown>
    for (const sensor of Object.values(device)) {
      if (typeof sensor !== "object" || sensor === null) continue
      for (const [key, val] of Object.entries(sensor as Record<string, unknown>)) {
        if (/^temp\d+_input$/.test(key) && typeof val === "number") return val
      }
    }
    return null
  } catch {
    return null
  }
}

export function createCpuState(intervalMs: number) {
  const initialSamples = readAllCpuSamples()

  const usageState = createPoll<CpuPollState>(
    { usage: 0, coreUsages: initialSamples.cores.map(() => 0), prevSamples: initialSamples },
    intervalMs,
    (prev) => {
      const curr = readAllCpuSamples()
      const usage = computeUsage(curr.aggregate, prev.prevSamples.aggregate)
      const coreUsages = curr.cores.map((sample, i) =>
        computeUsage(sample, prev.prevSamples.cores[i] ?? sample),
      )
      return { usage, coreUsages, prevSamples: curr }
    },
  )

  const tempState = createPoll<number | null>(null, intervalMs, async () => {
    try {
      return parseCpuTemp(await execAsync("sensors -j"))
    } catch {
      return null
    }
  })

  return {
    usage: usageState((s) => s.usage),
    coreUsages: usageState((s) => s.coreUsages),
    temp: tempState,
  }
}
