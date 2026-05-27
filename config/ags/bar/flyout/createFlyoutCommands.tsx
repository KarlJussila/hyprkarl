import { Gdk } from "ags/gtk4"
import { type FlyoutPlacement } from "../layout/placement.ts"
import { useWidgetCommands } from "../widgets/shared/useWidgetCommands.ts"
import type { NormalizedFlyoutConfig } from "./flyoutTypes.ts"
import type { NormalizedClickCommandsConfig } from "../widgets/shared/normalize.ts"

type Options = {
  flyout: NormalizedFlyoutConfig
  placement: FlyoutPlacement
  monitor: Gdk.Monitor
  id: string
  label: string
  commands: NormalizedClickCommandsConfig
  secondaryFallback?: (() => void) | undefined
  extraTokens?: Record<string, (() => void) | undefined>
  renderContent: (closeFlyout: () => void) => JSX.Element
}

export function createFlyoutCommands({
  flyout,
  placement,
  monitor,
  id,
  label,
  commands,
  secondaryFallback,
  extraTokens,
  renderContent,
}: Options) {
  return useWidgetCommands({
    commands,
    secondaryFallback,
    tokens: extraTokens,
    flyout: { config: flyout, placement, monitor, id, label, renderContent },
  })
}
