import { createState } from "ags"
import { Gdk, Gtk } from "ags/gtk4"
import { type FlyoutPlacement } from "../../layout/placement.ts"
import AttachedFlyout from "../../overlays/flyout/AttachedFlyout.tsx"
import Button from "../../primitives/Button.tsx"
import { type Accessor } from "ags"
import type { NormalizedFlyoutConfig } from "./flyoutTypes.ts"

type Props = {
  buttonClass: string
  placement: FlyoutPlacement
  monitor: Gdk.Monitor
  flyoutName: string
  flyout: NormalizedFlyoutConfig
  hexpand?: boolean
  halign?: Gtk.Align
  tooltipText?: string | Accessor<string>
  visible?: boolean | Accessor<boolean>
  execPrimary?: () => void
  execSecondary?: () => void
  execMiddle?: () => void
  children?: JSX.Element | Array<JSX.Element>
  renderFlyoutContent: (closeFlyout: () => void) => JSX.Element
}

export default function FlyoutButton({
  buttonClass,
  placement,
  monitor,
  flyoutName,
  flyout,
  hexpand,
  halign,
  tooltipText,
  visible,
  execPrimary,
  execSecondary,
  execMiddle,
  children,
  renderFlyoutContent,
}: Props) {
  const [flyoutOpen, setFlyoutOpen] = createState(false)
  const [triggerWidget, setTriggerWidget] = createState<Gtk.Widget | null>(null)
  const closeFlyout = () => setFlyoutOpen(false)

  if (flyout.enabled) {
    const mountedFlyout = (
      <AttachedFlyout
        name={flyoutName}
        placement={placement}
        monitor={monitor}
        trigger={triggerWidget}
        open={flyoutOpen}
        onRequestClose={closeFlyout}
        align={flyout.align}
        gap={flyout.gap}
      >
        {renderFlyoutContent(closeFlyout)}
      </AttachedFlyout>
    )

    void mountedFlyout
  }

  return (
    <Button
      class={buttonClass}
      hexpand={hexpand}
      halign={halign}
      tooltipText={tooltipText}
      visible={visible}
      execSecondary={execSecondary}
      execMiddle={execMiddle}
      $={flyout.enabled
        ? (self) => {
            setTriggerWidget(self)
            self.connect("destroy", () => {
              setTriggerWidget(null)
            })
          }
        : undefined}
      execPrimary={flyout.enabled
        ? () => setFlyoutOpen(!flyoutOpen())
        : execPrimary}
    >
      {children}
    </Button>
  )
}
