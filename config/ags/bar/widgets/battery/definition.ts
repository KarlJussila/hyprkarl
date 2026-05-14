import type {
  NormalizedBatteryWidgetConfig,
  WidgetDefinitionByKind,
} from "../../configuration.ts"
import {
  normalizeBatteryIndicatorMetrics,
  normalizeBatteryTooltipConfig,
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
  tooltip: {
    charging: "{power}↑ {time}",
    discharging: "{power}↓ {time}",
    plugged: "Plugged in {percentage}",
    fallback: "{percentage}",
  },
  indicator: {
    width: 14,
    height: 8,
    borderWidth: 1,
    terminalWidth: 2,
    terminalHeight: 4,
    chargingGlyph: "󱐋",
    chargingGlyphFontSize: 6,
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
    tooltip: normalizeBatteryTooltipConfig(id, definition.tooltip, batteryDefaults.tooltip),
    indicator: normalizeBatteryIndicatorMetrics(
      id,
      definition.advanced?.indicator,
      batteryDefaults.indicator,
    ),
  }
}
