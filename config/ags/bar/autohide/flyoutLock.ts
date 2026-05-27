import { createComputed, createState } from "ags"

const [lockCount, setLockCount] = createState(0)

export const flyoutLocked = createComputed(() => lockCount() > 0)

export function acquireFlyoutLock(): () => void {
  setLockCount((n) => n + 1)
  return () => setLockCount((n) => Math.max(0, n - 1))
}
