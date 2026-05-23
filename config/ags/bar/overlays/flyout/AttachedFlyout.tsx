import { Accessor, createEffect, createState } from "ags"
import { Gtk } from "ags/gtk4"
import { type FlyoutAlign } from "./flyoutTypes"
import { type FlyoutPlacement } from "../../layout/placement"
import FlyoutWindow, { type FlyoutWindowProps } from "./FlyoutWindow"
import {
  computeFlyoutMargins,
  measureWidget,
  rootRelativeAnchorBounds,
} from "./flyoutGeometry"

type Props = Omit<FlyoutWindowProps, "margins" | "revealTrigger" | "onReveal" | "onBodyReady"> & {
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
  const [bodyWidget, setBodyWidget] = createState<Gtk.Box | null>(null)
  const [margins, setMargins] = createState({ nearEdge: 0, crossAxis: 0, edgeClass: "" })
  const monitorGeometry = monitor.get_geometry()

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

    setMargins(computeFlyoutMargins({
      edge: placement.edge,
      align,
      anchorWidth: rootRelativeBounds.width,
      anchorHeight: rootRelativeBounds.height,
      anchorX: rootOrigin.x + rootRelativeBounds.x,
      anchorY: rootOrigin.y + rootRelativeBounds.y,
      flyoutSize: measureWidget(bodyWidget()),
      gap,
      monitorWidth: monitorGeometry.width,
      monitorHeight: monitorGeometry.height,
    }))
  }

  // Tracks open(), trigger(), and bodyWidget() — re-runs when any changes.
  createEffect(() => {
    open()
    updatePosition()
  })

  return (
    <FlyoutWindow
      {...flyout}
      placement={placement}
      monitor={monitor}
      open={open}
      margins={margins}
      revealTrigger={trigger}
      revealTransition={placement.flyout.direction}
      onReveal={updatePosition}
      onBodyReady={setBodyWidget}
    />
  )
}
