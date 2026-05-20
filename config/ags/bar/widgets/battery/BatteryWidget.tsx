import { Gdk, Gtk } from "ags/gtk4"
import { type FlyoutPlacement } from "../../layout/placement.ts"
import FlyoutButton from "../shared/FlyoutButton.tsx"
import { createWidgetFlyoutName } from "../shared/instanceNames.ts"
import BatteryIndicator from "./BatteryIndicator"
import { createBatteryState } from "./batteryState"
import { formatBatteryPercentage } from "./batteryStateShared.ts"
import PowerProfileMenu from "./PowerProfileMenu"
import type { NormalizedFlyoutConfig } from "../../overlays/flyout/flyoutTypes.ts"
import type {
  NormalizedBatteryIndicatorMetrics,
  NormalizedBatteryTooltipConfig,
} from "./types.ts"

type Props = {
  id: string
  placement: FlyoutPlacement
  monitor: Gdk.Monitor
  showPercentage: boolean
  lowThreshold: number
  flyout: NormalizedFlyoutConfig
  tooltip: NormalizedBatteryTooltipConfig
  indicator: NormalizedBatteryIndicatorMetrics
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
}: Props) {
  const batteryState = createBatteryState(tooltip)

  const batteryContent = (
    <box
      class={`widget-battery-display orientation-${placement.orientation} is-${placement.orientation}`}
      orientation={placement.isVertical ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
      spacing={0}
      hexpand={placement.isVertical}
      halign={placement.isVertical ? Gtk.Align.CENTER : Gtk.Align.FILL}
      valign={placement.isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
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
          class="widget-battery-percent"
          valign={Gtk.Align.CENTER}
          label={batteryState.percentage(formatBatteryPercentage)}
        />
      )}
    </box>
  )

  return (
    <FlyoutButton
      widgetClass="widget-battery-button"
      placement={placement}
      monitor={monitor}
      flyoutName={createWidgetFlyoutName("battery-menu", id, monitor.connector)}
      flyout={flyout}
      tooltipText={batteryState.tooltipText}
      visible={batteryState.isPresent}
      renderFlyoutContent={(closeFlyout) => (
        <PowerProfileMenu
          activeProfile={batteryState.activePowerProfile}
          profiles={batteryState.availablePowerProfiles}
          onSelect={(profileName) => {
            batteryState.setActivePowerProfile(profileName)
            closeFlyout()
          }}
        />
      )}
    >
      {batteryContent}
    </FlyoutButton>
  )
}
