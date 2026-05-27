import { createComputed, createEffect } from "ags"
import { Gdk, Gtk } from "ags/gtk4"
import { timeout, type Timer } from "ags/time"
import { type BarOrientation } from "../layout/placement.ts"
import { CommonButtonProps } from "./shared"

type Props = CommonButtonProps<Gtk.Button> & {
  orientation?: BarOrientation
  hexpand?: boolean
  halign?: Gtk.Align
  execPrimary?: () => void
  execSecondary?: () => void
  execMiddle?: () => void
}

export default function Button({
  $: setup,
  class: className = "",
  orientation = "horizontal",
  hexpand,
  halign,
  tooltipText,
  visible,
  children,
  execPrimary,
  execSecondary,
  execMiddle,
}: Props) {
  let pressTimer: Timer | null = null

  function press(button: Gtk.Button, action: () => void) {
    action()
    button.add_css_class("is-pressed")
    pressTimer?.cancel()
    pressTimer = timeout(120, () => {
      button.remove_css_class("is-pressed")
      pressTimer = null
    })
  }

  const resolvedClassName = typeof className === "string"
    ? `widget-button ${className}`.trim()
    : createComputed(() => `widget-button ${className()}`.trim())

  const setupButton = (button: Gtk.Button) => {
    button.valign = Gtk.Align.FILL
    if (typeof tooltipText === "string") {
      button.set_tooltip_text(tooltipText)
    } else if (tooltipText) {
      createEffect(() => {
        button.set_tooltip_text(tooltipText())
      })
    }
    setup?.(button)
  }

  const button = (
    <button
      class={resolvedClassName}
      hexpand={hexpand ?? orientation === "vertical"}
      halign={halign ?? Gtk.Align.FILL}
      visible={visible}
      $={setupButton}
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
