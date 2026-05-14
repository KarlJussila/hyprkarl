import { Accessor, createEffect, createState, onCleanup } from "ags"
import { Gtk } from "ags/gtk4"
import { Timer, interval } from "ags/time"
import { type FlyoutAlign } from "../../configuration"
import { type FlyoutPlacement } from "../../layout/placement"
import FlyoutWindow, { type FlyoutWindowProps } from "./FlyoutWindow"
import {
  computeFlyoutPosition,
  measureWidget,
  rootRelativeAnchorBounds,
} from "./flyoutGeometry"

type Props = Omit<FlyoutWindowProps, "position" | "frameSnapClass" | "revealTrigger" | "onReveal" | "onFrameReady"> & {
  placement: FlyoutPlacement
  trigger: Accessor<Gtk.Widget | null>
  align?: FlyoutAlign
  gap?: number
}

export default function AttachedFlyout({
  placement,
  open,
  trigger,
  monitor,
  align = "center",
  gap = 6,
  ...flyout
}: Props) {
  const animationDuration = 220
  const [frameWidget, setFrameWidget] = createState<Gtk.Box | null>(null)
  const [frameSnapClass, setFrameSnapClass] = createState("")
  const [flyoutPosition, setFlyoutPosition] = createState({ x: 0, y: 0 })
  const monitorGeometry = monitor.get_geometry()
  let animationTracker: Timer | null = null

  function clearAnimationTracker() {
    animationTracker?.cancel()
    animationTracker = null
  }

  function currentFlyoutSize() {
    const frame = frameWidget()
    if (!frame) {
      return { width: 0, height: 0 }
    }

    const measuredFrame = measureWidget(frame)
    const frameAllocation = frame.get_allocation()

    return {
      width: frameAllocation.width > 0 ? frameAllocation.width : measuredFrame.width,
      height: frameAllocation.height > 0 ? frameAllocation.height : measuredFrame.height,
    }
  }

  function updatePosition() {
    const triggerWidget = trigger()
    if (!triggerWidget) return

    const rootWidget = triggerWidget.get_root()
    if (!(rootWidget instanceof Gtk.Widget)) return
    const rootCoordinateWidget = rootWidget instanceof Gtk.Window
      ? (rootWidget.get_child() ?? rootWidget)
      : rootWidget

    const rootOrigin = placement.window.origin({
      monitorWidth: monitorGeometry.width,
      monitorHeight: monitorGeometry.height,
      rootAllocation: rootCoordinateWidget.get_allocation(),
    })
    const rootRelativeBounds = rootRelativeAnchorBounds({
      anchorWidget: triggerWidget,
      rootWidget: rootCoordinateWidget,
    })
    if (!rootRelativeBounds) return

    const nextFlyoutPosition = computeFlyoutPosition({
      edge: placement.edge,
      align,
      anchorWidth: rootRelativeBounds.width,
      anchorHeight: rootRelativeBounds.height,
      anchorX: rootOrigin.x + rootRelativeBounds.x,
      anchorY: rootOrigin.y + rootRelativeBounds.y,
      flyoutSize: currentFlyoutSize(),
      gap,
      monitorWidth: monitorGeometry.width,
      monitorHeight: monitorGeometry.height,
    })

    setFrameSnapClass(nextFlyoutPosition.edgeClass)
    setFlyoutPosition({
      x: nextFlyoutPosition.x,
      y: nextFlyoutPosition.y,
    })
  }

  function trackAnimatedPosition() {
    clearAnimationTracker()
    let elapsed = 0

    updatePosition()

    // The flyout's measured size changes while the revealer animates, so we keep
    // nudging its position until the animation settles. Otherwise edge-clamped menus
    // visibly "jump" after the first frame.
    animationTracker = interval(16, () => {
      updatePosition()
      elapsed += 16

      if (elapsed >= animationDuration) {
        clearAnimationTracker()
      }
    })
  }

  createEffect(() => {
    open()
    trackAnimatedPosition()
  })

  onCleanup(() => {
    clearAnimationTracker()
  })

  return (
    <FlyoutWindow
      {...flyout}
      placement={placement}
      monitor={monitor}
      open={open}
      position={flyoutPosition}
      frameSnapClass={frameSnapClass}
      revealTrigger={trigger}
      revealTransition={placement.flyout.direction}
      onReveal={updatePosition}
      onFrameReady={setFrameWidget}
    />
  )
}
