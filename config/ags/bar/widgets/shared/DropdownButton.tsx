import { createState } from "ags"
import { Gdk, Gtk } from "ags/gtk4"
import type { NormalizedDropdownConfig } from "../../configuration.ts"
import { type DropdownPlacement } from "../../layout/placement.ts"
import AttachedDropdown from "../../overlays/dropdown/AttachedDropdown.tsx"
import Button from "../../primitives/Button.tsx"
import { type Accessor } from "ags"

type Props = {
  buttonClass: string
  placement: DropdownPlacement
  monitor: Gdk.Monitor
  dropdownName: string
  dropdown: NormalizedDropdownConfig
  hexpand?: boolean
  halign?: Gtk.Align
  tooltipText?: string | Accessor<string>
  visible?: boolean | Accessor<boolean>
  children?: JSX.Element | Array<JSX.Element>
  renderDropdownContent: (closeDropdown: () => void) => JSX.Element
}

export default function DropdownButton({
  buttonClass,
  placement,
  monitor,
  dropdownName,
  dropdown,
  hexpand,
  halign,
  tooltipText,
  visible,
  children,
  renderDropdownContent,
}: Props) {
  const [dropdownOpen, setDropdownOpen] = createState(false)
  const [triggerWidget, setTriggerWidget] = createState<Gtk.Widget | null>(null)
  const closeDropdown = () => setDropdownOpen(false)

  if (dropdown.enabled) {
    const mountedDropdown = (
      <AttachedDropdown
        name={dropdownName}
        placement={placement}
        monitor={monitor}
        trigger={triggerWidget}
        open={dropdownOpen}
        onRequestClose={closeDropdown}
        align={dropdown.align}
        gap={dropdown.gap}
      >
        {renderDropdownContent(closeDropdown)}
      </AttachedDropdown>
    )

    void mountedDropdown
  }

  return (
    <Button
      class={buttonClass}
      hexpand={hexpand}
      halign={halign}
      tooltipText={tooltipText}
      visible={visible}
      $={dropdown.enabled
        ? (self) => {
            setTriggerWidget(self)
            self.connect("destroy", () => {
              setTriggerWidget(null)
            })
          }
        : undefined}
      execPrimary={dropdown.enabled
        ? () => setDropdownOpen(!dropdownOpen())
        : undefined}
    >
      {children}
    </Button>
  )
}
