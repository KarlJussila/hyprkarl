import { createState } from "ags"
import { Gdk, Gtk } from "ags/gtk4"
import { type NormalizedBatteryWidgetConfig } from "../../configuration"
import { type DropdownPlacement } from "../../layout/placement"
import AttachedDropdown from "../../overlays/dropdown/AttachedDropdown"
import Button from "../../primitives/Button"
import BatteryIndicator from "./BatteryIndicator"
import { createBatteryState, formatBatteryPercentage } from "./batteryState"
import PowerProfileMenu from "./PowerProfileMenu"

let nextPowerProfileMenuId = 1

type Props = {
  placement: DropdownPlacement
  monitor: Gdk.Monitor
  config: NormalizedBatteryWidgetConfig
}

export default function BatteryWidget({ placement, monitor, config }: Props) {
  const batteryState = createBatteryState()
  const [powerProfileMenuOpen, setPowerProfileMenuOpen] = createState(false)
  const [triggerButton, setTriggerButton] = createState<Gtk.Widget | null>(null)
  const powerProfileMenuId = nextPowerProfileMenuId++

  if (config.dropdown.enabled) {
    const mountedPowerProfileDropdown = (
      <AttachedDropdown
        name={`battery-menu-${monitor.connector ?? "monitor"}-${powerProfileMenuId}`}
        placement={placement}
        monitor={monitor}
        trigger={triggerButton}
        open={powerProfileMenuOpen}
        onRequestClose={() => setPowerProfileMenuOpen(false)}
        align={config.dropdown.align}
        gap={config.dropdown.gap}
      >
        <PowerProfileMenu
          activeProfile={batteryState.activePowerProfile}
          profiles={batteryState.availablePowerProfiles}
          onSelect={(profileName) => {
            batteryState.setActivePowerProfile(profileName)
            setPowerProfileMenuOpen(false)
          }}
        />
      </AttachedDropdown>
    )

    void mountedPowerProfileDropdown
  }

  const batteryContent = placement.isVertical
    ? (
        <box
          class="battery-display orientation-vertical"
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
            <label class="battery-percent" label={batteryState.percentage(formatBatteryPercentage)} />
          )}
        </box>
      )
    : (
        <box class="battery-display orientation-horizontal" spacing={0}>
          <BatteryIndicator
            orientation={placement.orientation}
            level={batteryState.percentage}
            charging={batteryState.isCharging}
            lowThreshold={config.lowThreshold}
            metrics={config.indicator}
          />
          {config.showPercentage && (
            <label class="battery-percent" label={batteryState.percentage(formatBatteryPercentage)} />
          )}
        </box>
      )

  return (
    <Button
      class={`battery-button orientation-${placement.orientation}`}
      hexpand={placement.isVertical}
      halign={placement.isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      $={config.dropdown.enabled
        ? (self) => {
            setTriggerButton(self)
            self.connect("destroy", () => {
              setTriggerButton(null)
            })
          }
        : undefined}
      visible={batteryState.isPresent}
      execPrimary={config.dropdown.enabled
        ? () => setPowerProfileMenuOpen(!powerProfileMenuOpen())
        : undefined}
    >
      {batteryContent}
    </Button>
  )
}

