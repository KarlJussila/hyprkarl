import { createComputed, type Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import Button from "../../button/Button"

type Props = {
  fill?: boolean
  icons: {
    collapsed: string
    expanded: string
  }
  hasItems: Accessor<boolean>
  open: Accessor<boolean>
  onToggle: () => void
}

export default function TrayExpander({
  fill = false,
  icons,
  hasItems,
  open,
  onToggle,
}: Props) {
  const triggerIcon = createComputed(() => open() ? icons.expanded : icons.collapsed)
  const buttonStateClass = hasItems((itemsAvailable) =>
    itemsAvailable ? "" : "tray-expander-empty",
  )

  return (
    <box
      class="tray-expander segmented-group-item"
      hexpand={fill}
      halign={fill ? Gtk.Align.FILL : Gtk.Align.CENTER}
    >
      <Button
        class={buttonStateClass}
        hexpand={fill}
        halign={fill ? Gtk.Align.FILL : Gtk.Align.CENTER}
        execPrimary={onToggle}
      >
        <box hexpand={fill} halign={Gtk.Align.CENTER}>
          <image iconName={triggerIcon} pixelSize={14} />
        </box>
      </Button>
    </box>
  )
}
