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

type Props = Omit<DropdownWindowProps, "position" | "frameSnapClass" | "revealTrigger" | "onReveal" | "onFrameReady"> & {
  trigger: Accessor<Gtk.Widget | null>
  align?: DropdownAlign
  gap?: number
}

export default function AttachedDropdown({
  trigger,
  monitor,
  align = "center",
  gap = 6,
  ...dropdown
}: Props) {
  const [frameWidget, setFrameWidget] = createState<Gtk.Box | null>(null)
  const [frameSnapClass, setFrameSnapClass] = createState("")
  const [dropdownPosition, setDropdownPosition] = createState({ x: 0, y: 0 })
  const monitorGeometry = monitor.get_geometry()

  function updatePosition() {
    const triggerWidget = trigger()
    if (!triggerWidget) return

    const rootWidget = triggerWidget.get_root() as Gtk.Widget | null
    if (!rootWidget) return

    const [translated, triggerX, triggerY] = triggerWidget.translate_coordinates(rootWidget, 0, 0)
    if (!translated) return

    const nextDropdownPosition = computeDropdownPosition({
      align,
      anchorAllocation: triggerWidget.get_allocation(),
      anchorX: triggerX,
      anchorY: triggerY,
      dropdownSize: measureWidget(frameWidget()),
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

  return (
    <DropdownWindow
      {...dropdown}
      monitor={monitor}
      position={dropdownPosition}
      frameSnapClass={frameSnapClass}
      revealTrigger={trigger}
      onReveal={updatePosition}
      onFrameReady={setFrameWidget}
    />
  )
}
