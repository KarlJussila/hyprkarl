import { createComputed } from "ags"
import { Gdk, Gtk } from "ags/gtk4"
import { timeout } from "ags/time"
import { CommonButtonProps } from "./shared"

type Props = CommonButtonProps<Gtk.Button> & {
  execPrimary?: () => void
  execSecondary?: () => void
  execMiddle?: () => void
  halign?: Gtk.Align
}

export default function Button({
  $: setup,
  class: className = "",
  execPrimary,
  execSecondary,
  execMiddle,
  halign = Gtk.Align.CENTER,
  hexpand = true,
  visible,
  children,
}: Props) {
  function press(button: Gtk.Button, action: () => void) {
    action()
    button.add_css_class("is-pressed")
    timeout(120, () => button.remove_css_class("is-pressed"))
  }

  const resolvedClassName = typeof className === "string"
    ? `widget-button ${className}`.trim()
    : createComputed(() => `widget-button ${className()}`.trim())

  const button = (
    <button
      class={resolvedClassName}
      hexpand={hexpand}
      halign={halign}
      visible={visible}
      $={setup}
    >
      {execPrimary && (
        <Gtk.GestureClick
          propagationPhase={Gtk.PropagationPhase.CAPTURE}
          button={Gdk.BUTTON_PRIMARY}
          onPressed={() => press(button, execPrimary)}
        />
      )}
      {execSecondary && (
        <Gtk.GestureClick
          propagationPhase={Gtk.PropagationPhase.CAPTURE}
          button={Gdk.BUTTON_SECONDARY}
          onPressed={() => press(button, execSecondary)}
        />
      )}
      {execMiddle && (
        <Gtk.GestureClick
          propagationPhase={Gtk.PropagationPhase.CAPTURE}
          button={Gdk.BUTTON_MIDDLE}
          onPressed={() => press(button, execMiddle)}
        />
      )}
      {children}
    </button>
  ) as Gtk.Button

  return button
}
