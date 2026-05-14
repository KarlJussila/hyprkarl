import { Accessor, createComputed, createEffect, onCleanup } from "ags"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import app from "ags/gtk4/app"
import { type FlyoutPlacement, placementClasses } from "../../layout/placement"
import FlyoutSurface from "./FlyoutSurface"
import { createFlyoutVisibility } from "./flyoutVisibility"

type FlyoutCoordinates = {
  x: number
  y: number
}

export type FlyoutWindowProps = {
  placement: FlyoutPlacement
  name: string
  monitor: Gdk.Monitor
  open: Accessor<boolean>
  position?: Accessor<FlyoutCoordinates>
  frameSnapClass?: Accessor<string>
  revealTrigger?: Accessor<unknown>
  revealTransition?: "down" | "up" | "right" | "left"
  onReveal?: () => void
  onRequestClose?: () => void
  windowClass?: string
  surfaceClass?: string
  children?: JSX.Element | Array<JSX.Element>
  onFrameReady?: (frame: Gtk.Box) => void
}

export default function FlyoutWindow({
  placement,
  name,
  monitor,
  open,
  position,
  frameSnapClass,
  revealTrigger = open,
  revealTransition = "down",
  onReveal = () => {},
  onRequestClose,
  windowClass = "flyout-window",
  surfaceClass = "flyout-surface",
  children,
  onFrameReady = () => {},
}: FlyoutWindowProps) {
  const { TOP, LEFT, RIGHT, BOTTOM } = Astal.WindowAnchor
  const revealDuration = 180
  const transitionType = revealTransition === "up"
    ? Gtk.RevealerTransitionType.SLIDE_UP
    : revealTransition === "right"
      ? Gtk.RevealerTransitionType.SLIDE_RIGHT
      : revealTransition === "left"
        ? Gtk.RevealerTransitionType.SLIDE_LEFT
        : Gtk.RevealerTransitionType.SLIDE_DOWN

  let windowLayout: Gtk.Fixed | null = null
  const monitorGeometry = monitor.get_geometry()
  const resolvedPosition = createComputed(() => position ? position() : { x: 0, y: 0 })
  const resolvedFrameSnapClass = createComputed(() => frameSnapClass ? frameSnapClass() : "")
  const { windowVisible, contentRevealed } = createFlyoutVisibility({
    open,
    revealTrigger,
    revealDuration,
    onReveal,
  })

  const shieldLayer = (
    <box
      class="flyout-shield"
      canTarget
      widthRequest={monitorGeometry.width}
      heightRequest={monitorGeometry.height}
    >
      <Gtk.GestureClick
        button={0}
        onPressed={() => onRequestClose?.()}
      />
    </box>
  ) as Gtk.Box

  const surface = (
    <FlyoutSurface
      placement={placement}
      frameSnapClass={resolvedFrameSnapClass}
      contentRevealed={contentRevealed}
      transitionDuration={revealDuration}
      transitionType={transitionType}
      surfaceClass={surfaceClass}
      onFrameReady={onFrameReady}
    >
      {children}
    </FlyoutSurface>
  ) as Gtk.Widget

  createEffect(() => {
    const { x, y } = resolvedPosition()
    windowLayout?.move(surface, x, y)
  })

  const flyoutWindow = (
    <window
      name={name}
      class={`${windowClass} ${placementClasses(placement)}`}
      application={app}
      visible={windowVisible}
      gdkmonitor={monitor}
      anchor={TOP | LEFT | RIGHT | BOTTOM}
      exclusivity={Astal.Exclusivity.IGNORE}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.ON_DEMAND}
      decorated={false}
      resizable={false}
      hideOnClose
      $={(self) => {
        windowLayout = new Gtk.Fixed()
        windowLayout.put(shieldLayer, 0, 0)
        windowLayout.put(surface, 0, 0)
        self.set_child(windowLayout)
      }}
    />
  ) as Astal.Window

  app.add_window(flyoutWindow)

  onCleanup(() => {
    flyoutWindow.destroy()
    windowLayout = null
  })

  return flyoutWindow
}
