import { Gdk, Gtk } from "ags/gtk4"
import { type NormalizedBatteryWidgetConfig } from "../../configuration.ts"
import { type DropdownPlacement } from "../../layout/placement.ts"
import DropdownButton from "../shared/DropdownButton.tsx"
import BatteryIndicator from "./BatteryIndicator"
import { createBatteryState, formatBatteryPercentage } from "./batteryState"
import PowerProfileMenu from "./PowerProfileMenu"

type Props = {
  placement: DropdownPlacement
  monitor: Gdk.Monitor
  config: NormalizedBatteryWidgetConfig
}

export default function BatteryWidget({ placement, monitor, config }: Props) {
  const batteryState = createBatteryState()

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
            <label class="widget-battery-percent" label={batteryState.percentage(formatBatteryPercentage)} />
          )}
        </box>
      )
    : (
        <box class="widget-battery-display orientation-horizontal is-horizontal" spacing={0}>
          <BatteryIndicator
            orientation={placement.orientation}
            level={batteryState.percentage}
            charging={batteryState.isCharging}
            lowThreshold={config.lowThreshold}
            metrics={config.indicator}
          />
          {config.showPercentage && (
            <label class="widget-battery-percent" label={batteryState.percentage(formatBatteryPercentage)} />
          )}
        </box>
      )

  return (
    <DropdownButton
      buttonClass={`widget-battery-button orientation-${placement.orientation} is-${placement.orientation}`}
      hexpand={placement.isVertical}
      halign={placement.isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      placement={placement}
      monitor={monitor}
      dropdownName={`battery-menu-${monitor.connector ?? "monitor"}`}
      dropdown={config.dropdown}
      visible={batteryState.isPresent}
      renderDropdownContent={(closeDropdown) => (
        <PowerProfileMenu
          activeProfile={batteryState.activePowerProfile}
          profiles={batteryState.availablePowerProfiles}
          onSelect={(profileName) => {
            batteryState.setActivePowerProfile(profileName)
            closeDropdown()
          }}
        />
      )}
    >
      {batteryContent}
    </DropdownButton>
  )
}
