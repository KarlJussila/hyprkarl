import { Accessor, createComputed } from "ags"
import { Gtk } from "ags/gtk4"
import { type FlyoutPlacement } from "../../layout/placement"

type Props = {
  placement: FlyoutPlacement
  frameSnapClass: Accessor<string>
  contentRevealed: Accessor<boolean>
  transitionDuration: number
  transitionType: Gtk.RevealerTransitionType
  surfaceClass: string
  children?: JSX.Element | Array<JSX.Element>
  onFrameReady: (frame: Gtk.Box) => void
}

export default function FlyoutSurface({
  placement,
  frameSnapClass,
  contentRevealed,
  transitionDuration,
  transitionType,
  surfaceClass,
  children,
  onFrameReady,
}: Props) {
  const frameClass = createComputed(() => {
    const classes = ["flyout-frame"]

    if (contentRevealed()) classes.push("revealed")

    const snapClass = frameSnapClass()
    if (snapClass) classes.push(snapClass)

    return classes.join(" ")
  })

  return (
    <box
      class={surfaceClass}
      hexpand={false}
      vexpand={false}
    >
      <box
        class={frameClass}
        hexpand={false}
        vexpand={false}
        halign={placement.flyout.frameHalign}
        valign={placement.flyout.frameValign}
        $={onFrameReady}
        >
        <revealer
          class={`flyout-revealer edge-${placement.edge}`}
          transitionType={transitionType}
          transitionDuration={transitionDuration}
          revealChild={contentRevealed}
        >
          <box
            class="flyout-body"
            spacing={2}
            orientation={Gtk.Orientation.VERTICAL}
          >
            {children}
          </box>
        </revealer>
      </box>
    </box>
  ) as Gtk.Box
}
