import { createState } from "ags"
import { Gdk, Gtk } from "ags/gtk4"
import Button from "../../button/Button"
import AttachedDropdown from "../../window/dropdown/AttachedDropdown"
import BatteryIndicator from "./BatteryIndicator"
import { createBatteryState, formatBatteryPercentage } from "./batteryState"
import PowerProfileMenu from "./PowerProfileMenu"

let nextPowerProfileMenuId = 1

type Props = {
  monitor: Gdk.Monitor
}

export default function Battery({ monitor }: Props) {
  const batteryState = createBatteryState()
  const [powerProfileMenuOpen, setPowerProfileMenuOpen] = createState(false)
  const [triggerButton, setTriggerButton] = createState<Gtk.Widget | null>(null)
  const powerProfileMenuId = nextPowerProfileMenuId++

  const mountedPowerProfileDropdown = (
    <AttachedDropdown
      name={`battery-menu-${monitor.connector ?? "monitor"}-${powerProfileMenuId}`}
      monitor={monitor}
      trigger={triggerButton}
      open={powerProfileMenuOpen}
      onRequestClose={() => setPowerProfileMenuOpen(false)}
      preferredAlign="center"
      gap={0}
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

  return (
    <Button
      $={(self) => {
        setTriggerButton(self)
        self.connect("destroy", () => {
          setTriggerButton(null)
        })
      }}
      visible={batteryState.isPresent}
      execPrimary={() => setPowerProfileMenuOpen(!powerProfileMenuOpen())}
    >
      <box spacing={4}>
        <BatteryIndicator
          level={batteryState.percentage}
          charging={batteryState.isCharging}
        />
        <label label={batteryState.percentage(formatBatteryPercentage)} />
      </box>
    </Button>
  )
}
