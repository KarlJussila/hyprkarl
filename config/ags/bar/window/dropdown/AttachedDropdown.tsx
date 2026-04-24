import { type Accessor, createState } from "ags"
import { Gtk } from "ags/gtk4"
import DropdownWindow, {
  type DropdownWindowProps,
} from "./DropdownWindow"
import {
  computeDropdownPosition,
  measureWidget,
  type DropdownAlign,
} from "./dropdownGeometry"

type Props = Omit<DropdownWindowProps, "position" | "frameEdgeClass" | "revealTrigger" | "onReveal" | "onFrameReady"> & {
  trigger: Accessor<Gtk.Widget | null>
  preferredAlign?: DropdownAlign
  gap?: number
}

export default function AttachedDropdown({
  trigger,
  monitor,
  preferredAlign = "center",
  gap = 6,
  ...dropdown
}: Props) {
  const [frameWidget, setFrameWidget] = createState<Gtk.Box | null>(null)
  const [frameEdgeClass, setFrameEdgeClass] = createState("")
  const [position, setPosition] = createState({ x: 0, y: 0 })
  const monitorGeometry = monitor.get_geometry()

  function updatePosition() {
    const triggerWidget = trigger()
    if (!triggerWidget) return

    const rootWidget = triggerWidget.get_root() as Gtk.Widget | null
    if (!rootWidget) return

    const [translated, triggerX, triggerY] = triggerWidget.translate_coordinates(rootWidget, 0, 0)
    if (!translated) return

    const nextPosition = computeDropdownPosition({
      align: preferredAlign,
      anchorAllocation: triggerWidget.get_allocation(),
      anchorX: triggerX,
      anchorY: triggerY,
      dropdownSize: measureWidget(frameWidget()),
      gap,
      monitorWidth: monitorGeometry.width,
      monitorHeight: monitorGeometry.height,
    })

    setFrameEdgeClass(nextPosition.edgeClass)
    setPosition({
      x: nextPosition.x,
      y: nextPosition.y,
    })
  }

  return (
    <DropdownWindow
      {...dropdown}
      monitor={monitor}
      position={position}
      frameEdgeClass={frameEdgeClass}
      revealTrigger={trigger}
      onReveal={updatePosition}
      onFrameReady={setFrameWidget}
    />
  )
}
