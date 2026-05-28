import { normalizeFlyoutConfig } from "../../flyout/normalizeFlyout.ts"
import type { NormalizedFlyoutConfig } from "../../flyout/flyoutTypes.ts"
import {
  normalizeClickCommandsConfig,
  normalizeSimpleTooltipConfig,
  type NormalizedClickCommandsConfig,
  type NormalizedSimpleTooltipConfig,
} from "./normalize.ts"

export function resolveSimpleTooltipText(tooltip: NormalizedSimpleTooltipConfig): string | undefined {
  return tooltip.text ? tooltip.text : undefined
}

export const commonWidgetSchema = {
  tooltip: normalizeSimpleTooltipConfig,
  commands: normalizeClickCommandsConfig,
}

export const commonWidgetDefaults: {
  tooltip: NormalizedSimpleTooltipConfig
  commands: NormalizedClickCommandsConfig
} = {
  tooltip: { text: "" },
  commands: { primary: undefined, secondary: undefined, tertiary: undefined },
}

export const flyoutWidgetSchema = {
  ...commonWidgetSchema,
  flyout: normalizeFlyoutConfig,
}

export const flyoutWidgetDefaults: typeof commonWidgetDefaults & {
  flyout: NormalizedFlyoutConfig
} = {
  ...commonWidgetDefaults,
  flyout: { align: "center", gap: 0 },
}
