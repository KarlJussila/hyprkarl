import { createEffect, createState, onCleanup, type Accessor } from "ags"
import { Timer, timeout } from "ags/time"

type Props = {
  open: Accessor<boolean>
  revealTrigger: Accessor<unknown>
  revealDuration: number
  onReveal: () => void
}

export function createDropdownVisibility({
  open,
  revealTrigger,
  revealDuration,
  onReveal,
}: Props) {
  const [windowVisible, setWindowVisible] = createState(false)
  const [contentRevealed, setContentRevealed] = createState(false)

  let hideTimer: Timer | null = null
  let revealTimer: Timer | null = null

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
      showWindow()
      revealContent()
      return
    }

    if (!windowVisible()) return

    hideContent()
  })

  onCleanup(() => {
    clearHideTimer()
    clearRevealTimer()
  })

  return {
    windowVisible,
    contentRevealed,
  }
}
