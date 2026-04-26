import { createComputed, type Accessor } from "ags"
import { Gtk } from "ags/gtk4"

type Props = {
  frameSnapClass: Accessor<string>
  contentRevealed: Accessor<boolean>
  transitionDuration: number
  surfaceClass: string
  children?: JSX.Element | Array<JSX.Element>
  onFrameReady: (frame: Gtk.Box) => void
}

export default function DropdownSurface({
  frameSnapClass,
  contentRevealed,
  transitionDuration,
  surfaceClass,
  children,
  onFrameReady,
}: Props) {
  const frameClass = createComputed(() => {
    const classes = ["dropdown-frame"]

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
        $={onFrameReady}
      >
        <revealer
          class="dropdown-revealer"
          transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
          transitionDuration={transitionDuration}
          revealChild={contentRevealed}
        >
          <box class="dropdown-body" spacing={2} orientation={Gtk.Orientation.VERTICAL}>
            {children}
          </box>
        </revealer>
      </box>
    </box>
  ) as Gtk.Box
}
