import type {
  NormalizedBatteryWidgetConfig,
  WidgetDefinitionByKind,
} from "../../configuration.ts"
import {
  normalizeBatteryIndicatorMetrics,
  normalizeBoolean,
  normalizeDropdownConfig,
  normalizeUnitInterval,
  widgetContext,
} from "../shared/normalize.ts"

const batteryDefaults: Omit<NormalizedBatteryWidgetConfig, "kind"> = {
  showPercentage: true,
  lowThreshold: 0.15,
  dropdown: {
    enabled: true,
    align: "center",
    gap: 0,
  },
  indicator: {
    width: 16,
    height: 10,
    borderWidth: 2,
    terminalWidth: 3,
    terminalHeightRatio: 0.4,
    chargingGlyph: "󱐋",
    chargingGlyphFontSize: 8,
    chargingGlyphFontFamily: "JetBrains Mono Nerd Font Propo",
  },
}

export function normalizeBatteryWidgetConfig(
  id: string,
  definition: WidgetDefinitionByKind["battery"],
): NormalizedBatteryWidgetConfig {
  return {
    kind: "battery",
    showPercentage: normalizeBoolean(
      widgetContext(id, "showPercentage"),
      definition.showPercentage,
      batteryDefaults.showPercentage,
    ),
    lowThreshold: normalizeUnitInterval(
      widgetContext(id, "lowThreshold"),
      definition.lowThreshold,
      batteryDefaults.lowThreshold,
    ),
    dropdown: normalizeDropdownConfig(id, definition.dropdown, batteryDefaults.dropdown),
    indicator: normalizeBatteryIndicatorMetrics(
      id,
      definition.advanced?.indicator,
      batteryDefaults.indicator,
    ),
  }
}

