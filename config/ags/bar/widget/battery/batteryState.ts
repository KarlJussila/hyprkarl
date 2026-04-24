import { createBinding, type Accessor } from "ags"
import AstalBattery from "gi://AstalBattery"
import AstalPowerProfiles from "gi://AstalPowerProfiles"

export type BatteryState = {
  isPresent: Accessor<boolean>
  percentage: Accessor<number>
  isCharging: Accessor<boolean>
  activePowerProfile: Accessor<string>
  availablePowerProfiles: Array<AstalPowerProfiles.Profile>
  setActivePowerProfile: (profileName: string) => void
}

export function formatBatteryPercentage(percentage: number) {
  return `${Math.floor(percentage * 100)}%`
}

export function createBatteryState(): BatteryState {
  const batteryService = AstalBattery.get_default()
  const powerProfileService = AstalPowerProfiles.get_default()
  return {
    isPresent: createBinding(batteryService, "isPresent"),
    percentage: createBinding(batteryService, "percentage"),
    isCharging: createBinding(batteryService, "iconName")(
      (iconName) => typeof iconName === "string" && iconName.includes("charging"),
    ),
    activePowerProfile: createBinding(powerProfileService, "activeProfile"),
    availablePowerProfiles: powerProfileService.get_profiles(),
    setActivePowerProfile: (profileName) => {
      powerProfileService.set_active_profile(profileName)
    },
  }
}
