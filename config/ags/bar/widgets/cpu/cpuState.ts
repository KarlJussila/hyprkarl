import { createPoll } from "ags/time"
import { readFile } from "ags/file"

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
      // Prefer Tdie (temp2) over Tctl (temp1) on modern AMD k10temp
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

export function createCpuState(intervalMs: number) {
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
