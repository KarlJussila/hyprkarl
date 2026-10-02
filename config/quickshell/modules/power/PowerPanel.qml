pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower
import "../../ui/panels"

Item {
  id: root

  required property var theme
  required property var config
  required property bool active

  signal externalCommandRequested(string command)

  readonly property var battery: UPower.displayDevice
  readonly property real preferredWidth: theme.panel.powerWidth

  implicitWidth: parent?.width ?? 0
  implicitHeight: content.implicitHeight

  function batteryStatus(): string {
    if (!battery?.ready) return "Reading battery"
    switch (battery.state) {
    case UPowerDeviceState.Charging: return "Charging"
    case UPowerDeviceState.Discharging: return "On battery"
    case UPowerDeviceState.Empty: return "Empty"
    case UPowerDeviceState.FullyCharged: return "Fully charged"
    case UPowerDeviceState.PendingCharge: return "Waiting to charge"
    case UPowerDeviceState.PendingDischarge: return "On external power"
    default: return UPower.onBattery ? "On battery" : "On external power"
    }
  }

  function formatDuration(seconds: real): string {
    if (seconds <= 0) return ""
    const totalMinutes = Math.round(seconds / 60)
    const hours = Math.floor(totalMinutes / 60)
    const minutes = totalMinutes % 60
    if (hours === 0) return `${minutes} min`
    return minutes === 0 ? `${hours} hr` : `${hours} hr ${minutes} min`
  }

  function batteryEstimate(): string {
    if (!battery) return ""
    if (battery.state === UPowerDeviceState.Charging) return formatDuration(battery.timeToFull)
    if (battery.state === UPowerDeviceState.Discharging) return formatDuration(battery.timeToEmpty)
    return ""
  }

  function batteryMetrics(): string {
    if (!battery) return ""
    const values = []
    if (battery.changeRate > 0) {
      const direction = battery.state === UPowerDeviceState.Charging
        ? "↑ "
        : battery.state === UPowerDeviceState.Discharging ? "↓ " : ""
      values.push(`${direction}${battery.changeRate.toFixed(1)} W`)
    }
    if (battery.healthSupported) values.push(`${Math.round(battery.healthPercentage)}% health`)
    return values.join("  ·  ")
  }

  function performanceDetail(): string {
    if (PowerProfiles.profile !== PowerProfile.Performance) return ""
    switch (PowerProfiles.degradationReason) {
    case PerformanceDegradationReason.LapDetected: return "limited on lap"
    case PerformanceDegradationReason.HighTemperature: return "limited by heat"
    default: return "active"
    }
  }

  PanelLayout {
    id: content

    width: parent.width
    theme: root.theme
    title: "Power"

    BatterySummary {
      visible: root.battery?.isPresent ?? false
      width: parent.width
      theme: root.theme
      battery: root.battery
      config: root.config
      status: root.batteryStatus()
      estimate: root.batteryEstimate()
      metrics: root.batteryMetrics()
    }

    PanelSectionLabel {
      theme: root.theme
      navigationSection: "profiles"
      text: "Power profile"
    }

    Text {
      visible: PowerProfiles.holds.length > 0
      width: parent.width
      text: `${PowerProfiles.holds.length} application hold${PowerProfiles.holds.length === 1 ? "" : "s"} the current profile. Choosing another profile releases ${PowerProfiles.holds.length === 1 ? "it" : "them"}.`
      color: root.theme.panel.foreground
      opacity: 0.65
      wrapMode: Text.Wrap
      font.family: root.theme.panel.font
      font.pixelSize: root.theme.typography.readoutSize
    }

    PanelRow {
      width: parent.width
      theme: root.theme
      navigationSection: "profiles"
      icon: "󰌪"
      title: "Power saver"
      detail: PowerProfiles.profile === PowerProfile.PowerSaver ? "active" : ""
      selected: PowerProfiles.profile === PowerProfile.PowerSaver
      action: () => PowerProfiles.profile = PowerProfile.PowerSaver
    }

    PanelRow {
      width: parent.width
      theme: root.theme
      navigationSection: "profiles"
      icon: "󰾅"
      title: "Balanced"
      detail: PowerProfiles.profile === PowerProfile.Balanced ? "active" : ""
      selected: PowerProfiles.profile === PowerProfile.Balanced
      action: () => PowerProfiles.profile = PowerProfile.Balanced
    }

    PanelRow {
      visible: PowerProfiles.hasPerformanceProfile
      width: parent.width
      theme: root.theme
      navigationSection: "profiles"
      icon: "󰓅"
      title: "Performance"
      detail: root.performanceDetail()
      selected: PowerProfiles.profile === PowerProfile.Performance
      action: () => PowerProfiles.profile = PowerProfile.Performance
    }

    PanelAction {
      visible: root.config.powerCommand?.length > 0
      width: parent.width
      theme: root.theme
      navigationSection: "actions"
      icon: "󰐥"
      text: "Power actions"
      action: () => root.externalCommandRequested(root.config.powerCommand)
    }
  }
}
