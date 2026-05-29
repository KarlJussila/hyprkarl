import { createState } from "ags"
import { Gdk } from "ags/gtk4"
import { type FlyoutPlacement } from "../../layout/placement.ts"
import { createFlyout } from "../../flyout/createFlyout.tsx"
import type { WidgetClicks, WidgetFlyout } from "./types.ts"
import { resolveCommand } from "./resolveCommand.ts"

type CommandToken = (() => void) | undefined

type FlyoutBinding = {
  config: WidgetFlyout
  placement: FlyoutPlacement
  monitor: Gdk.Monitor
  id: string
  label: string
  renderContent: (closeFlyout: () => void) => JSX.Element
}

type UseWidgetCommandsOptions = {
  commands: WidgetClicks
  primaryFallback?: CommandToken
  secondaryFallback?: CommandToken
  tertiaryFallback?: CommandToken
  tokens?: Record<string, CommandToken>
  flyout?: FlyoutBinding
}

export function useWidgetCommands({
  commands,
  primaryFallback,
  secondaryFallback,
  tertiaryFallback,
  tokens: extraTokens,
  flyout,
}: UseWidgetCommandsOptions) {
  const tokens: Record<string, CommandToken> = { ...(extraTokens ?? {}) }
  let triggerSetup: ReturnType<typeof createFlyout>["triggerSetup"] = undefined
  let resolvedPrimaryFallback = primaryFallback

  if (flyout) {
    const [flyoutOpen, setFlyoutOpen] = createState(false)
    const toggleFlyout = () => setFlyoutOpen(!flyoutOpen())
    tokens.flyout = toggleFlyout
    if (resolvedPrimaryFallback === undefined) {
      resolvedPrimaryFallback = toggleFlyout
    }
    triggerSetup = createFlyout({
      flyout: flyout.config,
      placement: flyout.placement,
      monitor: flyout.monitor,
      id: flyout.id,
      label: flyout.label,
      flyoutOpen,
      setFlyoutOpen,
      renderContent: flyout.renderContent,
    }).triggerSetup
  }

  return {
    execPrimary: resolveCommand(commands.primary, resolvedPrimaryFallback, tokens),
    execSecondary: resolveCommand(commands.secondary, secondaryFallback, tokens),
    execTertiary: resolveCommand(commands.tertiary, tertiaryFallback, tokens),
    triggerSetup,
  }
}
