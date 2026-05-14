import type {
  NormalizedBluetoothWidgetConfig,
  WidgetDefinitionByKind,
} from "../../configuration.ts"
import {
  normalizeRequiredCommand,
  widgetContext,
} from "../shared/normalize.ts"

const bluetoothDefaults: Omit<NormalizedBluetoothWidgetConfig, "kind"> = {
  command: "hk-launch-bluetooth",
}

export function normalizeBluetoothWidgetConfig(
  id: string,
  definition: WidgetDefinitionByKind["bluetooth"],
): NormalizedBluetoothWidgetConfig {
  return {
    kind: "bluetooth",
    command: normalizeRequiredCommand(
      widgetContext(id, "command"),
      definition.command,
      bluetoothDefaults.command,
    ),
  }
}
