import { createState } from "ags"
import { Gdk, Gtk } from "ags/gtk4"
import { type DropdownPlacement } from "../../barPlacement"
import Button from "../../button/Button"
import AttachedDropdown from "../../window/dropdown/AttachedDropdown"
import BatteryIndicator from "./BatteryIndicator"
import { createBatteryState, formatBatteryPercentage } from "./batteryState"
import PowerProfileMenu from "./PowerProfileMenu"

let nextPowerProfileMenuId = 1

type Props = {
  placement: DropdownPlacement
  monitor: Gdk.Monitor
}

export default function Battery({ placement, monitor }: Props) {
  const batteryState = createBatteryState()
  const [powerProfileMenuOpen, setPowerProfileMenuOpen] = createState(false)
  const [triggerButton, setTriggerButton] = createState<Gtk.Widget | null>(null)
  const powerProfileMenuId = nextPowerProfileMenuId++

  const mountedPowerProfileDropdown = (
    <AttachedDropdown
      name={`battery-menu-${monitor.connector ?? "monitor"}-${powerProfileMenuId}`}
      placement={placement}
      monitor={monitor}
      trigger={triggerButton}
      open={powerProfileMenuOpen}
      onRequestClose={() => setPowerProfileMenuOpen(false)}
      align="center"
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

  const batteryContent = placement.isVertical
    ? (
        <box
          class="battery-display orientation-vertical"
          orientation={Gtk.Orientation.VERTICAL}
          spacing={2}
          hexpand={placement.isVertical}
          halign={Gtk.Align.CENTER}
        >
          <BatteryIndicator
            orientation={placement.orientation}
            level={batteryState.percentage}
            charging={batteryState.isCharging}
          />
          <label class="battery-percent" label={batteryState.percentage(formatBatteryPercentage)} />
        </box>
      )
    : (
        <box class="battery-display orientation-horizontal" spacing={4}>
          <BatteryIndicator
            level={batteryState.percentage}
            charging={batteryState.isCharging}
          />
          <label class="battery-percent" label={batteryState.percentage(formatBatteryPercentage)} />
        </box>
      )

  return (
    <Button
      class={`battery-button orientation-${placement.orientation}`}
      hexpand={placement.isVertical}
      halign={placement.isVertical ? Gtk.Align.FILL : Gtk.Align.CENTER}
      $={(self) => {
        setTriggerButton(self)
        self.connect("destroy", () => {
          setTriggerButton(null)
        })
      }}
      visible={batteryState.isPresent}
      execPrimary={() => setPowerProfileMenuOpen(!powerProfileMenuOpen())}
    >
      {batteryContent}
    </Button>
  )
}
