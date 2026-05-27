import { Gdk, Gtk } from "ags/gtk4"
import { type FlyoutPlacement } from "../../layout/placement.ts"
import Button from "../../primitives/Button.tsx"
import { createFlyoutCommands } from "../../flyout/createFlyoutCommands.tsx"
import BatteryIndicator from "./BatteryIndicator"
import { createBatteryState } from "./batteryState"
import { formatReadoutPercent } from "../shared/formatters.ts"
import PowerProfileMenu from "./PowerProfileMenu"
import type { NormalizedFlyoutConfig } from "../../flyout/flyoutTypes.ts"
import type {
  NormalizedBatteryIndicatorMetrics,
  NormalizedBatteryTooltipConfig,
} from "./types.ts"
import type { NormalizedClickCommandsConfig } from "../shared/normalize.ts"

type Props = {
  id: string
  placement: FlyoutPlacement
  monitor: Gdk.Monitor
  showPercentage: boolean
  lowThreshold: number
  flyout: NormalizedFlyoutConfig
  tooltip: NormalizedBatteryTooltipConfig
  indicator: NormalizedBatteryIndicatorMetrics
  commands: NormalizedClickCommandsConfig
}

export default function BatteryWidget({
  id,
  placement,
  monitor,
  showPercentage,
  lowThreshold,
  flyout,
  tooltip,
  indicator,
  commands,
}: Props) {
  const batteryState = createBatteryState(tooltip)

  const { execPrimary, execSecondary, execMiddle, triggerSetup } = createFlyoutCommands({
    flyout,
    placement,
    monitor,
    id,
    label: "battery-menu",
    commands,
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
  })

  return (
    <Button
      class={`widget-battery-button widget-glyph-button is-${placement.orientation}`}
      orientation={placement.orientation}
      tooltipText={batteryState.tooltipText}
      visible={batteryState.isPresent}
      execPrimary={execPrimary}
      execSecondary={execSecondary}
      execMiddle={execMiddle}
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
