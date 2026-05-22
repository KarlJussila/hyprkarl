import type { Accessor } from "ags"
import { createComputed, createEffect, createState, onCleanup } from "ags"
import { Astal } from "ags/gtk4"
import type { Timer } from "ags/time"
import { timeout } from "ags/time"

export const REVEAL_DURATION = 200

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
  onPointerEnterHotzone: () => void
  onRevealAnimationComplete: () => void
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

  function cancelDebounce() {
    debounceTimer?.cancel()
    debounceTimer = null
  }

  createEffect(() => {
    const shouldReveal =
      !forcedHidden() && (!autohideMode() || pointerOver() || config.flyoutOpen())

    cancelDebounce()

    if (shouldReveal) {
      setWindowVisible(true)
      timeout(1, () => setContentRevealed(true))
      return
    }

    if (!windowVisible()) return

    debounceTimer = timeout(300, () => {
      // setContentRevealed(false)
      setWindowVisible(false)
      debounceTimer = null
    })
  })

  onCleanup(cancelDebounce)

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
    onPointerEnterHotzone: () => { if (!pointerOver()) setPointerOver(true) },

    onRevealAnimationComplete() {
      // if (!contentRevealed()) {
      //   setWindowVisible(false)
      // }
    },

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
