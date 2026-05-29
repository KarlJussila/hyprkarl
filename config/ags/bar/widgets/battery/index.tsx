import { Gtk } from "ags/gtk4"
import Button from "../../primitives/Button.tsx"
import BatteryIndicator from "./Indicator.tsx"
import { createBatteryState, type BatteryTooltipTemplates, type BatteryIndicatorMetrics } from "./state.ts"
import { formatReadoutPercent } from "../shared/formatters.ts"
import PowerProfileMenu from "./PowerProfileMenu.tsx"
import { useWidgetCommands } from "../shared/useWidgetCommands.ts"
import { mergeConfig, defaultFlyout, type WidgetClicks, type WidgetFlyout, type WidgetProps } from "../shared/types.ts"

export type BatteryConfig = {
  showPercentage?: boolean
  lowThreshold?: number
  flyout?: WidgetFlyout
  tooltip?: Partial<BatteryTooltipTemplates>
  indicator?: Partial<BatteryIndicatorMetrics>
  commands?: WidgetClicks
}

type BatteryDefaults = {
  showPercentage: boolean
  lowThreshold: number
  flyout: WidgetFlyout
  tooltip: BatteryTooltipTemplates
  indicator: BatteryIndicatorMetrics
  commands: WidgetClicks
}

export const defaults: BatteryDefaults = {
  showPercentage: true,
  lowThreshold: 0.15,
  flyout: defaultFlyout,
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
    fontSize: 6,
    fontFamily: "JetBrains Mono Nerd Font Propo",
    glyphs: {
      charging: { glyph: "󱐋", glyphOffset: [0, 0] },
    },
  },
  commands: {},
}

export default function BatteryWidget({ id, config, placement, monitor }: WidgetProps<BatteryConfig>) {
  const cfg = mergeConfig(defaults, config)
  const { showPercentage, lowThreshold, flyout, tooltip, indicator, commands } = cfg
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
