import { createState } from "ags"
import { Gdk, Gtk } from "ags/gtk4"
import type { Accessor } from "ags"
import { type FlyoutPlacement } from "../layout/placement.ts"
import AttachedFlyout from "./AttachedFlyout.tsx"
import type { FlyoutConfig } from "./flyoutTypes.ts"

type FlyoutOptions = {
  flyout: FlyoutConfig
  placement: FlyoutPlacement
  monitor: Gdk.Monitor
  id: string
  label: string
  flyoutOpen: Accessor<boolean>
  setFlyoutOpen: (v: boolean) => void
  renderContent: (closeFlyout: () => void) => JSX.Element
}

export function createFlyout({
  flyout,
  placement,
  monitor,
  id,
  label,
  flyoutOpen,
  setFlyoutOpen,
  renderContent,
}: FlyoutOptions): { triggerSetup: ((self: Gtk.Button) => void) | undefined } {
  const [triggerWidget, setTriggerWidget] = createState<Gtk.Widget | null>(null)
  const closeFlyout = () => setFlyoutOpen(false)
  const flyoutName = `${label}-${id}-${monitor.connector ?? "monitor"}`

  // Evaluating this JSX registers the layer-shell window with AGS; the element itself is discarded.
  void (
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
      {renderContent(closeFlyout)}
    </AttachedFlyout>
  )

  const triggerSetup = (self: Gtk.Button) => {
    setTriggerWidget(self)
    self.connect("destroy", () => setTriggerWidget(null))
  }

  return { triggerSetup }
}
