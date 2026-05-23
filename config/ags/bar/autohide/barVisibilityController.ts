import type { Accessor } from "ags"
import { createComputed, createEffect, createState, onCleanup } from "ags"
import { Astal } from "ags/gtk4"
import type { Timer } from "ags/time"
import { timeout } from "ags/time"

export const REVEAL_DURATION = 100

export type BarVisibilityStatus = {
  autohide: boolean
  exclusive: boolean
  hidden: boolean
}

export type BarVisibilityController = {
  windowVisible: Accessor<boolean>
  contentRevealed: Accessor<boolean>
  exclusivity: Accessor<Astal.Exclusivity>
  onPointerLeaveBar: () => void
  onPointerEnter: () => void
  setAutohide: (value: boolean) => void
  setExclusive: (value: boolean) => void
  forceShow: () => void
  forceHide: () => void
  getStatus: () => BarVisibilityStatus
}

export function createBarVisibilityController(config: {
  autohide: boolean
  exclusive: boolean
  flyoutOpen: Accessor<boolean>
}): BarVisibilityController {
  const initialRevealed = !config.autohide

  const [autohideMode, setAutohideMode] = createState(config.autohide)
  const [exclusiveMode, setExclusiveMode] = createState(config.exclusive)
  const [forcedHidden, setForcedHidden] = createState(false)
  const [pointerOver, setPointerOver] = createState(false)
  const [windowVisible, setWindowVisible] = createState(initialRevealed)
  const [contentRevealed, setContentRevealed] = createState(initialRevealed)

  let debounceTimer: Timer | null = null
  let hideTimer: Timer | null = null

  function cancelTimers() {
    debounceTimer?.cancel()
    debounceTimer = null
    hideTimer?.cancel()
    hideTimer = null
  }

  createEffect(() => {
    const shouldReveal =
      !forcedHidden() && (!autohideMode() || pointerOver() || config.flyoutOpen())

    cancelTimers()

    if (shouldReveal) {
      setWindowVisible(true)
      timeout(1, () => setContentRevealed(true))
      return
    }

    if (!windowVisible()) return

    debounceTimer = timeout(300, () => {
      setContentRevealed(false)
      debounceTimer = null
      hideTimer = timeout(REVEAL_DURATION, () => {
        setWindowVisible(false)
        hideTimer = null
      })
    })
  })

  onCleanup(cancelTimers)

  const exclusivity = createComputed(() =>
    contentRevealed() && exclusiveMode()
      ? Astal.Exclusivity.EXCLUSIVE
      : Astal.Exclusivity.NORMAL
  )

  return {
    windowVisible,
    contentRevealed,
    exclusivity,

    onPointerLeaveBar: () => setPointerOver(false),
    onPointerEnter: () => { if (!pointerOver()) setPointerOver(true) },

    setAutohide(value: boolean) {
      setForcedHidden(false)
      setAutohideMode(value)
    },

    setExclusive(value: boolean) {
      setExclusiveMode(value)
    },

    forceShow() {
      setForcedHidden(false)
    },

    forceHide() {
      setPointerOver(false)
      setForcedHidden(true)
    },

    getStatus(): BarVisibilityStatus {
      return {
        autohide: autohideMode(),
        exclusive: exclusiveMode(),
        hidden: !contentRevealed(),
      }
    },
  }
}
