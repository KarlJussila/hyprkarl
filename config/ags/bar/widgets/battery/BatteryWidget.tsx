import { Gtk } from "ags/gtk4"
import Button from "../../primitives/Button.tsx"
import BatteryIndicator from "./BatteryIndicator.tsx"
import { createBatteryState, type BatteryTooltipTemplates, type BatteryIndicatorMetrics } from "./batteryState.ts"
import { formatReadoutPercent } from "../shared/formatters.ts"
import PowerProfileMenu from "./PowerProfileMenu.tsx"
import { useWidgetCommands } from "../shared/useWidgetCommands.ts"
import type { WidgetRenderArgs } from "../shared/widgetSpec.tsx"
import type { NormalizedFlyoutConfig } from "../../flyout/flyoutTypes.ts"
import type { NormalizedClickCommandsConfig } from "../shared/normalize.ts"

type Config = {
  showPercentage: boolean
  lowThreshold: number
  flyout: NormalizedFlyoutConfig
  tooltip: BatteryTooltipTemplates
  indicator: BatteryIndicatorMetrics
  commands: NormalizedClickCommandsConfig
}

export default function BatteryWidget({ id, config, placement, monitor }: WidgetRenderArgs<Config>) {
  const { showPercentage, lowThreshold, flyout, tooltip, indicator, commands } = config
  const batteryState = createBatteryState(tooltip)

  const { execPrimary, execSecondary, execTertiary, triggerSetup } = useWidgetCommands({
    commands,
    flyout: {
      config: flyout,
      placement,
      monitor,
      id,
      label: "battery-menu",
      renderContent: (closeFlyout) => (
        <PowerProfileMenu
          activeProfile={batteryState.activePowerProfile}
          profiles={batteryState.availablePowerProfiles}
          onSelect={(profileName) => {
            batteryState.setActivePowerProfile(profileName)
            closeFlyout()
          }}
        />
      ),
    },
  })

  return (
    <Button
      class={`widget-battery-button widget-glyph-button is-${placement.orientation}`}
      orientation={placement.orientation}
      tooltipText={batteryState.tooltipText}
      visible={batteryState.isPresent}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execTertiary={execTertiary}
      $={triggerSetup}
    >
      <box
        class={`widget-battery-display widget-icon-display is-${placement.orientation}`}
        orientation={placement.isVertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
        spacing={0}
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
      >
        <BatteryIndicator
          orientation={placement.orientation}
          level={batteryState.percentage}
          charging={batteryState.isCharging}
          lowThreshold={lowThreshold}
          metrics={indicator}
        />
        {showPercentage && (
          <label
            class="widget-battery-percent widget-readout widget-readout-percent"
            valign={Gtk.Align.CENTER}
            label={batteryState.percentage(formatReadoutPercent)}
          />
        )}
      </box>
    </Button>
  )
}
