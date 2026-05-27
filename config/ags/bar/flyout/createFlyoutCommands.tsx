import { createState } from "ags"
import { Gdk } from "ags/gtk4"
import { type FlyoutPlacement } from "../layout/placement.ts"
import { createFlyout } from "./createFlyout.tsx"
import type { NormalizedFlyoutConfig } from "./flyoutTypes.ts"
import type { NormalizedClickCommandsConfig } from "../widgets/shared/normalize.ts"
import { resolveCommand } from "../widgets/shared/resolveCommand.ts"

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
  extraTokens = {},
  renderContent,
}: Options) {
  const [flyoutOpen, setFlyoutOpen] = createState(false)
  const toggleFlyout = () => setFlyoutOpen(!flyoutOpen())
  const tokens = { flyout: toggleFlyout, ...extraTokens }

  const execPrimary = resolveCommand(commands.primary, flyout.enabled ? toggleFlyout : undefined, tokens)
  const execSecondary = resolveCommand(commands.secondary, secondaryFallback, tokens)
  const execMiddle = resolveCommand(commands.tertiary, undefined, tokens)

  const { triggerSetup } = createFlyout({ flyout, placement, monitor, id, label, flyoutOpen, setFlyoutOpen, renderContent })

  return { execPrimary, execSecondary, execMiddle, triggerSetup }
}
