import { Accessor, createEffect, createState, onCleanup } from "ags"
import { Timer, timeout } from "ags/time"
import { acquireFlyoutLock } from "../../autohide/flyoutLock"

type Props = {
  open: Accessor<boolean>
  revealTrigger: Accessor<unknown>
  revealDuration: number
  onReveal: () => void
}

export function createFlyoutVisibility({
  open,
  revealTrigger,
  revealDuration,
  onReveal,
}: Props) {
  const [windowVisible, setWindowVisible] = createState(false)
  const [contentRevealed, setContentRevealed] = createState(false)

  let hideTimer: Timer | null = null
  let revealTimer: Timer | null = null
  let releaseFlyoutLock: (() => void) | null = null

  function clearHideTimer() {
    hideTimer?.cancel()
    hideTimer = null
  }

  function clearRevealTimer() {
    revealTimer?.cancel()
    revealTimer = null
  }

  function showWindow() {
    if (!windowVisible()) {
      setWindowVisible(true)
    }
  }

  function revealContent() {
    revealTimer = timeout(1, () => {
      onReveal()
      setContentRevealed(true)
      revealTimer = null
    })
  }

  function hideContent() {
    setContentRevealed(false)

    hideTimer = timeout(revealDuration, () => {
      setWindowVisible(false)
      hideTimer = null
    })
  }

  createEffect(() => {
    const isOpen = open()
    revealTrigger()

    clearHideTimer()
    clearRevealTimer()

    if (isOpen) {
      if (!releaseFlyoutLock) {
        releaseFlyoutLock = acquireFlyoutLock()
      }
      showWindow()
      revealContent()
      return
    }

    if (releaseFlyoutLock) {
      releaseFlyoutLock()
      releaseFlyoutLock = null
    }

    if (!windowVisible()) return

    hideContent()
  })

  onCleanup(() => {
    clearHideTimer()
    clearRevealTimer()
    releaseFlyoutLock?.()
    releaseFlyoutLock = null
  })

  return {
    windowVisible,
    contentRevealed,
  }
}
