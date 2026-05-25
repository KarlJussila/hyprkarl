import { createBinding, createComputed, type Accessor } from "ags"
import AstalBattery from "gi://AstalBattery"
import AstalPowerProfiles from "gi://AstalPowerProfiles"
import { formatBatteryTooltip } from "./batteryTooltip.ts"
import type { NormalizedBatteryTooltipConfig } from "./types.ts"

export type BatteryState = {
  isPresent: Accessor<boolean>
  percentage: Accessor<number>
  isCharging: Accessor<boolean>
  tooltipText: Accessor<string> | undefined
  activePowerProfile: Accessor<string>
  availablePowerProfiles: Array<AstalPowerProfiles.Profile>
  setActivePowerProfile: (profileName: string) => void
}

export function createBatteryState(tooltipFormats: NormalizedBatteryTooltipConfig): BatteryState {
  const batteryService = AstalBattery.get_default()
  const powerProfileService = AstalPowerProfiles.get_default()
  const percentage = createBinding(batteryService, "percentage")
  const isCharging = createBinding(batteryService, "charging")
  const energyRate = createBinding(batteryService, "energyRate")
  const timeToEmpty = createBinding(batteryService, "timeToEmpty")
  const timeToFull = createBinding(batteryService, "timeToFull")

  return {
    isPresent: createBinding(batteryService, "isPresent"),
    percentage,
    isCharging,
    tooltipText: tooltipFormats.enabled
      ? createComputed(() => formatBatteryTooltip({
          percentage: percentage(),
          charging: isCharging(),
          energyRate: energyRate(),
          timeToEmpty: Number(timeToEmpty()),
          timeToFull: Number(timeToFull()),
          formats: tooltipFormats,
        }))
      : undefined,
    activePowerProfile: createBinding(powerProfileService, "activeProfile"),
    availablePowerProfiles: powerProfileService.get_profiles(),
    setActivePowerProfile: (profileName) => {
      powerProfileService.set_active_profile(profileName)
    },
  }
}
