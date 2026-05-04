import { type Accessor, createEffect, createState, onCleanup } from "ags"
import { Gtk } from "ags/gtk4"
import { type DropdownPlacement } from "../../barPlacement"
import { Timer, interval } from "ags/time"
import DropdownWindow, {
  type DropdownWindowProps,
} from "./DropdownWindow"
import {
  computeDropdownPosition,
  measureWidget,
  rootRelativeAnchorPosition,
  type DropdownAlign,
} from "./dropdownGeometry"

type Props = Omit<DropdownWindowProps, "position" | "frameSnapClass" | "revealTrigger" | "onReveal" | "onFrameReady"> & {
  placement: DropdownPlacement
  trigger: Accessor<Gtk.Widget | null>
  align?: DropdownAlign
  gap?: number
}

export default function AttachedDropdown({
  placement,
  open,
  trigger,
  monitor,
  align = "center",
  gap = 6,
  ...dropdown
}: Props) {
  const animationDuration = 220
  const [frameWidget, setFrameWidget] = createState<Gtk.Box | null>(null)
  const [frameSnapClass, setFrameSnapClass] = createState("")
  const [dropdownPosition, setDropdownPosition] = createState({ x: 0, y: 0 })
  const monitorGeometry = monitor.get_geometry()
  let animationTracker: Timer | null = null

  function clearAnimationTracker() {
    animationTracker?.cancel()
    animationTracker = null
  }

  function currentDropdownSize() {
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

  function trackAnimatedPosition() {
    clearAnimationTracker()
    let elapsed = 0

    updatePosition()

    animationTracker = interval(16, () => {
      updatePosition()
      elapsed += 16

      if (elapsed >= animationDuration) {
        clearAnimationTracker()
      }
    })
  }

  function updatePosition() {
    const triggerWidget = trigger()
    if (!triggerWidget) return
    const anchorWidget = triggerWidget

    const rootWidget = anchorWidget.get_root()
    if (!(rootWidget instanceof Gtk.Widget)) return
    const rootOrigin = placement.window.origin({
      monitorWidth: monitorGeometry.width,
      monitorHeight: monitorGeometry.height,
      rootAllocation: rootWidget.get_allocation(),
    })
    const rootRelativePosition = rootRelativeAnchorPosition({
      anchorWidget,
      rootWidget,
    })
    if (!rootRelativePosition) return

    const nextDropdownPosition = computeDropdownPosition({
      edge: placement.edge,
      align,
      anchorAllocation: anchorWidget.get_allocation(),
      anchorX: rootOrigin.x + rootRelativePosition.anchorX,
      anchorY: rootOrigin.y + rootRelativePosition.anchorY,
      dropdownSize: currentDropdownSize(),
      gap,
      monitorWidth: monitorGeometry.width,
      monitorHeight: monitorGeometry.height,
    })

    setFrameSnapClass(nextDropdownPosition.edgeClass)
    setDropdownPosition({
      x: nextDropdownPosition.x,
      y: nextDropdownPosition.y,
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
    <DropdownWindow
      {...dropdown}
      placement={placement}
      monitor={monitor}
      open={open}
      position={dropdownPosition}
      frameSnapClass={frameSnapClass}
      revealTrigger={trigger}
      revealTransition={placement.dropdown.flyout}
      onReveal={updatePosition}
      onFrameReady={setFrameWidget}
    />
  )
}
