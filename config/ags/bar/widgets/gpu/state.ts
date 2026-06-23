import { createPoll } from "ags/time"
import { readFile } from "ags/file"
import { execAsync } from "ags/process"

// GPU metrics have no event/DBus source — sysfs pseudo-files can't be watched —
// so this polls. Two battery traps are designed around here:
//   1. No subprocess on the fast path. AMD/Intel metrics are plain sysfs reads;
//      `nvidia-smi` only spawns when a card is NVIDIA, and `lspci` runs at most
//      once per card (cached) to resolve a display name.
//   2. A continuous poller must not pin a discrete GPU awake. Verified
//      empirically on amdgpu: reading a *suspended* card's sensors is harmless
//      (`gpu_busy_percent` returns EBUSY, VRAM returns cached values, no resume),
//      but reading an *active* discrete GPU's sensors (gpu_busy_percent,
//      vram_used, temp) re-arms its runtime autosuspend timer. Polling such a
//      card at an interval <= its autosuspend delay therefore keeps it awake
//      forever — exactly the trap a one-shot script (spawned per waybar tick)
//      avoids. So `pollGpu` throttles arming-sensor reads on a *suspendable*
//      card to slower than its autosuspend delay, replaying the last reading on
//      skipped ticks; the card then falls asleep when idle and selection drops
//      it. Selection and static data use only non-arming reads (runtime_status,
//      boot_vga, cached VRAM total). The always-on primary (boot_vga) is exempt.
//      Pin a specific card with `card`.

const DRM = "/sys/class/drm"
const BYTES_PER_GIB = 1073741824
const BYTES_PER_MIB = 1048576

export type GpuMetrics = {
  usage: number | null // 0..1
  vramUsed: number | null // bytes
  vramTotal: number | null // bytes
  temp: number | null // °C
  name: string
}

const EMPTY: GpuMetrics = { usage: null, vramUsed: null, vramTotal: null, temp: null, name: "" }

type Vendor = "amd" | "nvidia" | "intel" | "unknown"

function read(path: string): string | null {
  try {
    return readFile(path).trim()
  } catch {
    return null
  }
}

function readCardFile(card: string, rel: string): string | null {
  return read(`${DRM}/${card}/device/${rel}`)
}

function readCardBytes(card: string, rel: string): number | null {
  const v = readCardFile(card, rel)
  return v && /^\d+$/.test(v) ? Number(v) : null
}

// Total VRAM is a fixed hardware property — read it once per card and cache it.
// Keeping it off the per-tick path also guarantees selection never re-arms a
// card's autosuspend timer by reading it.
const vramTotalCache = new Map<string, number>()
function vramTotalOf(card: string): number | null {
  const cached = vramTotalCache.get(card)
  if (cached !== undefined) return cached
  const value = readCardBytes(card, "mem_info_vram_total")
  if (value !== null) vramTotalCache.set(card, value)
  return value
}

function vendorOf(card: string): Vendor {
  switch (readCardFile(card, "vendor")) {
    case "0x1002":
      return "amd"
    case "0x10de":
      return "nvidia"
    case "0x8086":
      return "intel"
    default:
      return "unknown"
  }
}

// DRM cards are sparsely numbered (card1, card2, …). Brute-force the low range
// rather than listing the directory — same approach the cpu widget uses for
// hwmon, and it keeps this module dependency-free (readFile only).
function listCards(): string[] {
  const cards: string[] = []
  for (let i = 0; i < 16; i++) {
    if (read(`${DRM}/card${i}/device/vendor`) !== null) cards.push(`card${i}`)
  }
  return cards
}

// Missing/"unsupported" runtime status means the card is always-on (e.g. an
// iGPU) — treat as active. Only an explicit "suspended" is skipped, so we never
// wake a sleeping dGPU.
function isActive(card: string): boolean {
  const status = readCardFile(card, "power/runtime_status")
  return status === null || status === "active" || status === "unsupported"
}

function isBootVga(card: string): boolean {
  return readCardFile(card, "boot_vga") === "1"
}

// A "suspendable" card can runtime-suspend (a discrete GPU with runtime PM
// enabled). Reading its live sensors re-arms the autosuspend timer, so those
// reads must be throttled below its autosuspend delay. The always-on primary
// (boot_vga) and cards without runtime PM are exempt. Stable for the session.
type SuspendInfo = { suspendable: boolean; delayMs: number }
const suspendInfoCache = new Map<string, SuspendInfo>()
function suspendInfoOf(card: string): SuspendInfo {
  const cached = suspendInfoCache.get(card)
  if (cached !== undefined) return cached
  const control = readCardFile(card, "power/control")
  const delayMs = readCardBytes(card, "power/autosuspend_delay_ms")
  const suspendable = control === "auto" && delayMs !== null && delayMs > 0 && !isBootVga(card)
  const info: SuspendInfo = { suspendable, delayMs: delayMs ?? 0 }
  suspendInfoCache.set(card, info)
  return info
}

// Prefer the most capable active card: highest VRAM, then the boot GPU. Only
// active cards are considered (via the non-arming runtime_status read), so while
// a dGPU sleeps the always-on iGPU is shown rather than its unavailable (EBUSY)
// live data; when the dGPU is genuinely in use it becomes active and wins on
// VRAM. Uses only non-arming reads (runtime_status, boot_vga, cached VRAM
// total), so running selection every tick never re-arms a card's autosuspend.
function selectBestCard(): string | null {
  const cards = listCards()
  const active = cards.filter(isActive)
  const pool = active.length > 0 ? active : cards

  let best: string | null = null
  let bestVram = -1
  let bestBoot = -1
  for (const card of pool) {
    const vram = vramTotalOf(card) ?? 0
    const boot = isBootVga(card) ? 1 : 0
    if (best === null || vram > bestVram || (vram === bestVram && boot > bestBoot)) {
      best = card
      bestVram = vram
      bestBoot = boot
    }
  }
  return best
}

// hwmon index under device/hwmon/ is the global hwmon number, so brute-force the
// range and cache the first temp1_input that exists. Stable for the session.
const tempFileCache = new Map<string, string | null>()
function tempFileFor(card: string): string | null {
  const cached = tempFileCache.get(card)
  if (cached !== undefined) return cached
  let found: string | null = null
  for (let i = 0; i < 24; i++) {
    const path = `${DRM}/${card}/device/hwmon/hwmon${i}/temp1_input`
    if (read(path) !== null) {
      found = path
      break
    }
  }
  tempFileCache.set(card, found)
  return found
}

function readTemp(card: string): number | null {
  const file = tempFileFor(card)
  if (!file) return null
  const raw = read(file)
  return raw && /^\d+$/.test(raw) ? Number(raw) / 1000 : null
}

function pciSlotOf(card: string): string | null {
  const match = readCardFile(card, "uevent")?.match(/PCI_SLOT_NAME=(\S+)/)
  return match ? match[1]! : null
}

function vendorLabel(vendor: Vendor): string {
  switch (vendor) {
    case "amd":
      return "AMD GPU"
    case "nvidia":
      return "NVIDIA GPU"
    case "intel":
      return "Intel GPU"
    default:
      return "GPU"
  }
}

// Names resolve to product_name when the kernel exposes it; otherwise a vendor
// label is shown immediately and refined once via lspci (cached forever after).
const nameCache = new Map<string, string>()
function nameOf(card: string): string {
  const cached = nameCache.get(card)
  if (cached !== undefined) return cached

  const product = readCardFile(card, "product_name")
  if (product) {
    nameCache.set(card, product)
    return product
  }

  const fallback = vendorLabel(vendorOf(card))
  nameCache.set(card, fallback)
  resolveNameViaLspci(card)
  return fallback
}

function resolveNameViaLspci(card: string) {
  const slot = pciSlotOf(card)
  if (!slot) return
  execAsync(["lspci", "-s", slot.replace(/^0000:/, "")])
    .then((out) => {
      const match = out.match(/:\s*(.+?)\s*$/)
      if (!match) return
      const name = match[1]!.replace(/\s*\(rev[^)]*\)\s*$/, "").replace(/\s*\[[0-9a-fA-F]{4}:[0-9a-fA-F]{4}\]/, "").trim()
      if (name) nameCache.set(card, name)
    })
    .catch(() => {})
}

function normalizeBus(bus: string): string {
  return bus.toLowerCase().replace(/^0+:/, "").replace(/^0000:/, "")
}

// NVIDIA exposes nothing useful in sysfs, so shell out. Only called when the
// selected card is NVIDIA and at least one metric is missing from sysfs.
async function queryNvidia(card: string): Promise<Partial<GpuMetrics>> {
  const slot = pciSlotOf(card)
  try {
    const out = await execAsync([
      "nvidia-smi",
      "--query-gpu=pci.bus_id,utilization.gpu,memory.used,memory.total,temperature.gpu",
      "--format=csv,noheader,nounits",
    ])
    for (const line of out.split("\n")) {
      const [bus, util, used, total, temp] = line.split(",").map((s) => s.trim())
      if (!bus) continue
      if (slot && normalizeBus(bus) !== normalizeBus(slot)) continue
      const usage = util && /^\d+$/.test(util) ? Number(util) / 100 : null
      const vramUsed = used && /^\d+$/.test(used) ? Number(used) * BYTES_PER_MIB : null
      const vramTotal = total && /^\d+$/.test(total) ? Number(total) * BYTES_PER_MIB : null
      const tempC = temp && /^\d+$/.test(temp) ? Number(temp) : null
      return { usage, vramUsed, vramTotal, temp: tempC }
    }
  } catch {}
  return {}
}

// Reads the live (arming) sensors. Calling this on an active discrete GPU
// re-arms its autosuspend timer — see the throttle in `pollGpu`.
function readSysfsMetrics(card: string, name: string): GpuMetrics {
  const busy = readCardFile(card, "gpu_busy_percent")
  const usage = busy && /^\d+$/.test(busy) ? Number(busy) / 100 : null
  return {
    usage,
    vramUsed: readCardBytes(card, "mem_info_vram_used"),
    vramTotal: vramTotalOf(card),
    temp: readTemp(card),
    name,
  }
}

// Per-card throttle state: wall-clock ms of the last arming-sensor read, and the
// metrics from that read to replay on skipped ticks.
const lastArmAt = new Map<string, number>()
const lastMetrics = new Map<string, GpuMetrics>()

function pollGpu(cardOverride: string): GpuMetrics | Promise<GpuMetrics> {
  const card = cardOverride || selectBestCard()
  if (!card) return EMPTY

  const name = nameOf(card)

  // A suspendable card must not be read more often than it can fall asleep, or
  // each read re-arms its autosuspend and pins it awake. On a throttled tick,
  // replay the last reading without touching the sensors; the card then sleeps
  // when idle, after which selection (runtime_status) drops it for the iGPU.
  // The gap is 2× the autosuspend delay to clear the kernel's suspend latency.
  const { suspendable, delayMs } = suspendInfoOf(card)
  if (suspendable && Date.now() - (lastArmAt.get(card) ?? 0) < delayMs * 2) {
    return lastMetrics.get(card) ?? { ...EMPTY, name }
  }
  if (suspendable) lastArmAt.set(card, Date.now())

  const sysfs = readSysfsMetrics(card, name)
  const complete =
    sysfs.usage !== null && sysfs.vramUsed !== null && sysfs.vramTotal !== null && sysfs.temp !== null

  if (vendorOf(card) !== "nvidia" || complete) {
    lastMetrics.set(card, sysfs)
    return sysfs
  }

  return queryNvidia(card).then((n) => {
    const merged: GpuMetrics = {
      usage: sysfs.usage ?? n.usage ?? null,
      vramUsed: sysfs.vramUsed ?? n.vramUsed ?? null,
      vramTotal: sysfs.vramTotal ?? n.vramTotal ?? null,
      temp: sysfs.temp ?? n.temp ?? null,
      name,
    }
    lastMetrics.set(card, merged)
    return merged
  })
}

export function createGpuState(intervalMs: number, card: string) {
  const state = createPoll<GpuMetrics>(EMPTY, intervalMs, () => pollGpu(card))
  return {
    usage: state((s) => s.usage),
    vramUsed: state((s) => s.vramUsed),
    vramTotal: state((s) => s.vramTotal),
    temp: state((s) => s.temp),
    name: state((s) => s.name),
  }
}

export function formatGiB(bytes: number | null): string | undefined {
  if (bytes === null) return undefined
  return `${(bytes / BYTES_PER_GIB).toFixed(1)}G`
}
