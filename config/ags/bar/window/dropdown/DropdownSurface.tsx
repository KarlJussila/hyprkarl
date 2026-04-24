import { createComputed, type Accessor } from "ags"
import { Gtk } from "ags/gtk4"

type Props = {
  frameEdgeClass: Accessor<string>
  contentRevealed: Accessor<boolean>
  transitionDuration: number
  surfaceClass: string
  children?: JSX.Element | Array<JSX.Element>
  onFrameReady: (frame: Gtk.Box) => void
}

export default function DropdownSurface({
  frameEdgeClass,
  contentRevealed,
  transitionDuration,
  surfaceClass,
  children,
  onFrameReady,
}: Props) {
  const frameClass = createComputed(() => {
    const classes = ["menu-surface-frame"]

    if (contentRevealed()) classes.push("revealed")

    const edgeClass = frameEdgeClass()
    if (edgeClass) classes.push(edgeClass)

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
        $={onFrameReady}
      >
        <revealer
          class="menu-surface-revealer"
          transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
          transitionDuration={transitionDuration}
          revealChild={contentRevealed}
        >
          <box class="menu-surface-body" spacing={2} orientation={Gtk.Orientation.VERTICAL}>
            {children}
          </box>
        </revealer>
      </box>
    </box>
  ) as Gtk.Box
}
