import { Accessor } from "ags"
import { Gtk } from "ags/gtk4"

export type ButtonChildren = JSX.Element | Array<JSX.Element>

export type CommonButtonProps<TWidget extends Gtk.Widget> = {
  $?: (widget: TWidget) => void
  class?: string | Accessor<string>
  hexpand?: boolean
  visible?: boolean | Accessor<boolean>
  children?: ButtonChildren
}

