import { Gdk, Gtk } from "ags/gtk4"
import { type NormalizedBatteryWidgetConfig } from "../../configuration.ts"
import { type FlyoutPlacement } from "../../layout/placement.ts"
import FlyoutButton from "../shared/FlyoutButton.tsx"
import { createWidgetFlyoutName } from "../shared/instanceNames.ts"
import BatteryIndicator from "./BatteryIndicator"
import { createBatteryState } from "./batteryState"
import { formatBatteryPercentage } from "./batteryStateShared.ts"
import PowerProfileMenu from "./PowerProfileMenu"

type Props = {
  id: string
  placement: FlyoutPlacement
  monitor: Gdk.Monitor
  config: NormalizedBatteryWidgetConfig
}

export default function BatteryWidget({ id, placement, monitor, config }: Props) {
  const batteryState = createBatteryState(config.tooltip)

  const batteryContent = placement.isVertical
    ? (
        <box
          class="widget-battery-display orientation-vertical is-vertical"
          orientation={Gtk.Orientation.VERTICAL}
          spacing={0}
          hexpand={placement.isVertical}
          halign={Gtk.Align.CENTER}
        >
          <BatteryIndicator
            orientation={placement.orientation}
            level={batteryState.percentage}
            charging={batteryState.isCharging}
            lowThreshold={config.lowThreshold}
            metrics={config.indicator}
          />
          {config.showPercentage && (
            <label
              class="widget-battery-percent"
              valign={Gtk.Align.CENTER}
              label={batteryState.percentage(formatBatteryPercentage)}
            />
          )}
        </box>
      )
    : (
        <box
          class="widget-battery-display orientation-horizontal is-horizontal"
          spacing={0}
          valign={Gtk.Align.CENTER}
        >
          <BatteryIndicator
            orientation={placement.orientation}
            level={batteryState.percentage}
            charging={batteryState.isCharging}
            lowThreshold={config.lowThreshold}
            metrics={config.indicator}
          />
          {config.showPercentage && (
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
      buttonClass={`widget-battery-button orientation-${placement.orientation} is-${placement.orientation}`}
      hexpand={placement.isVertical}
      halign={placement.isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      placement={placement}
      monitor={monitor}
      flyoutName={createWidgetFlyoutName("battery-menu", id, monitor.connector)}
      flyout={config.flyout}
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
