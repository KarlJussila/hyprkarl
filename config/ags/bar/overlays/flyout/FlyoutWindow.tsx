import { Accessor, createComputed, createEffect, onCleanup } from "ags"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import app from "ags/gtk4/app"
import { type BarEdge } from "../../configuration"
import { type FlyoutPlacement, placementClasses } from "../../layout/placement"
import { type FlyoutMargins } from "./flyoutGeometry"
import { createFlyoutVisibility } from "./flyoutVisibility"

export type FlyoutWindowProps = {
  placement: FlyoutPlacement
  name: string
  monitor: Gdk.Monitor
  open: Accessor<boolean>
  margins?: Accessor<FlyoutMargins>
  revealTrigger?: Accessor<unknown>
  revealTransition?: "down" | "up" | "right" | "left"
  onReveal?: () => void
  onRequestClose?: () => void
  windowClass?: string
  children?: JSX.Element | Array<JSX.Element>
  onBodyReady?: (body: Gtk.Box) => void
}

const revealTransitionTypes: Record<string, Gtk.RevealerTransitionType> = {
  up: Gtk.RevealerTransitionType.SLIDE_UP,
  right: Gtk.RevealerTransitionType.SLIDE_RIGHT,
  left: Gtk.RevealerTransitionType.SLIDE_LEFT,
  down: Gtk.RevealerTransitionType.SLIDE_DOWN,
}

function applyEdgeMargins(surface: Gtk.Widget, edge: BarEdge, nearEdge: number, crossAxis: number) {
  surface.set_margin_top(edge === "top" ? nearEdge : (edge === "left" || edge === "right") ? crossAxis : 0)
  surface.set_margin_bottom(edge === "bottom" ? nearEdge : 0)
  surface.set_margin_start(edge === "left" ? nearEdge : (edge === "top" || edge === "bottom") ? crossAxis : 0)
  surface.set_margin_end(edge === "right" ? nearEdge : 0)
}

export default function FlyoutWindow({
  placement,
  name,
  monitor,
  open,
  margins,
  revealTrigger = open,
  revealTransition = "down",
  onReveal = () => {},
  onRequestClose,
  windowClass = "flyout-window",
  children,
  onBodyReady = () => {},
}: FlyoutWindowProps) {
  const { TOP, LEFT, RIGHT, BOTTOM } = Astal.WindowAnchor
  const revealDuration = 180
  const transitionType = revealTransitionTypes[revealTransition] ?? Gtk.RevealerTransitionType.SLIDE_DOWN

  const monitorGeometry = monitor.get_geometry()
  const { windowVisible, contentRevealed } = createFlyoutVisibility({
    open,
    revealTrigger,
    revealDuration,
    onReveal,
  })

  const revealerClass = createComputed(() => {
    const classes = ["flyout-surface", "flyout-revealer", `edge-${placement.edge}`]
    if (contentRevealed()) classes.push("revealed")
    const snapClass = margins ? margins().edgeClass : ""
    if (snapClass) classes.push(snapClass)
    return classes.join(" ")
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
    <revealer
      class={revealerClass}
      hexpand={false}
      vexpand={false}
      halign={placement.flyout.halign}
      valign={placement.flyout.valign}
      transitionType={transitionType}
      transitionDuration={revealDuration}
      revealChild={contentRevealed}
    >
      <box
        class="flyout-body"
        spacing={2}
        orientation={Gtk.Orientation.VERTICAL}
        $={onBodyReady}
      >
        {children}
      </box>
    </revealer>
  ) as Gtk.Widget

  if (margins) {
    createEffect(() => {
      const { nearEdge, crossAxis } = margins()
      applyEdgeMargins(surface, placement.edge, nearEdge, crossAxis)
    })
  }

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
        const overlay = new Gtk.Overlay()
        overlay.set_child(shieldLayer)
        overlay.add_overlay(surface)
        self.set_child(overlay)
      }}
    />
  ) as Astal.Window

  app.add_window(flyoutWindow)

  onCleanup(() => {
    flyoutWindow.destroy()
  })

  return flyoutWindow
}
