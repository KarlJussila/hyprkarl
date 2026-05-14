import type {
  NormalizedNetworkWidgetConfig,
  WidgetDefinitionByKind,
} from "../../configuration.ts"
import {
  normalizeRequiredCommand,
  widgetContext,
} from "../shared/normalize.ts"

const networkDefaults: Omit<NormalizedNetworkWidgetConfig, "kind"> = {
  command: "hk-launch-wifi",
}

export function normalizeNetworkWidgetConfig(
  id: string,
  definition: WidgetDefinitionByKind["network"],
): NormalizedNetworkWidgetConfig {
  return {
    kind: "network",
    command: normalizeRequiredCommand(
      widgetContext(id, "command"),
      definition.command,
      networkDefaults.command,
    ),
  }
}
