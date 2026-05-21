import { createPoll } from "ags/time"
import { readFile } from "ags/file"

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

export function createRamState(intervalMs: number) {
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
