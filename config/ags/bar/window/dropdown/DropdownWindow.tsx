import app from "ags/gtk4/app"
import { Accessor, createComputed, createEffect, createState, onCleanup } from "ags"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import DropdownSurface from "./DropdownSurface"
import { createDropdownVisibility } from "./dropdownVisibility"

type DropdownCoordinates = {
  x: number
  y: number
}

export type DropdownWindowProps = {
  name: string
  monitor: Gdk.Monitor
  open: Accessor<boolean>
  position?: Accessor<DropdownCoordinates>
  frameSnapClass?: Accessor<string>
  revealTrigger?: Accessor<unknown>
  onReveal?: () => void
  onRequestClose?: () => void
  windowClass?: string
  surfaceClass?: string
  children?: JSX.Element | Array<JSX.Element>
  onFrameReady?: (frame: Gtk.Box) => void
}

export default function DropdownWindow({
  name,
  monitor,
  open,
  position,
  frameSnapClass,
  revealTrigger = open,
  onReveal = () => {},
  onRequestClose,
  windowClass = "dropdown-window",
  surfaceClass = "dropdown-surface",
  children,
  onFrameReady = () => {},
}: DropdownWindowProps) {
  const { TOP, LEFT, RIGHT, BOTTOM } = Astal.WindowAnchor
  const revealDuration = 180

  let windowLayout: Gtk.Fixed | null = null
  const monitorGeometry = monitor.get_geometry()
  const resolvedPosition = createComputed(() => position ? position() : { x: 0, y: 0 })
  const resolvedFrameSnapClass = createComputed(() => frameSnapClass ? frameSnapClass() : "")
  const { windowVisible, contentRevealed } = createDropdownVisibility({
    open,
    revealTrigger,
    revealDuration,
    onReveal,
  })

  const shieldLayer = (
    <box
      class="dropdown-shield"
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
    <DropdownSurface
      frameSnapClass={resolvedFrameSnapClass}
      contentRevealed={contentRevealed}
      transitionDuration={revealDuration}
      surfaceClass={surfaceClass}
      onFrameReady={onFrameReady}
    >
      {children}
    </DropdownSurface>
  ) as Gtk.Widget

  createEffect(() => {
    const { x, y } = resolvedPosition()
    windowLayout?.move(surface, x, y)
  })

  const dropdownWindow = (
    <window
      name={name}
      class={windowClass}
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

  app.add_window(dropdownWindow)

  onCleanup(() => {
    dropdownWindow.destroy()
    windowLayout = null
  })

  return dropdownWindow
}
