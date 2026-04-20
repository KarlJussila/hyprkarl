import { Gdk, Gtk } from "ags/gtk4"
import { timeout } from "ags/time"

type Props = {
  execPrimary?: () => void
  execSecondary?: () => void
  execMiddle?: () => void
  halign?: Gtk.Align
  popover?: Gtk.Popover
  children?: JSX.Element | Array<JSX.Element>
}

/* Custom button with click handling and popover integration */
export default function Button({ execPrimary, execSecondary, execMiddle, halign=Gtk.Align.CENTER, popover, children }: Props) {
    const button = (
        <button
            hexpand
            halign={halign}
        >
            {execPrimary && <Gtk.GestureClick
                propagationPhase={Gtk.PropagationPhase.CAPTURE}
                button={Gdk.BUTTON_PRIMARY}
                onPressed={() => {
                        execPrimary()
                        button.add_css_class("pressed")
                        timeout(120, () => button.remove_css_class("pressed"))
                    }
                }
            />}
            {execSecondary && <Gtk.GestureClick
                propagationPhase={Gtk.PropagationPhase.CAPTURE}
                button={Gdk.BUTTON_SECONDARY}
                onPressed={() => {
                        execSecondary()
                        button.add_css_class("pressed")
                        timeout(120, () => button.remove_css_class("pressed"))
                    }
                }
            />}
            {execMiddle && <Gtk.GestureClick
                propagationPhase={Gtk.PropagationPhase.CAPTURE}
                button={Gdk.BUTTON_MIDDLE}
               onPressed={() => {
                        execMiddle()
                        button.add_css_class("pressed")
                        timeout(120, () => button.remove_css_class("pressed"))
                    }
                }
            />}
            {children}
        </button>
    ) as Gtk.Button

    popover?.set_parent(button)

    return button
}