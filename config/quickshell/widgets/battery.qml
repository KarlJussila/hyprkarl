pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower
import "../components"
import "../features/power"

ShellButton {
  id: root

  required property string widgetId
  required property var config
  required property var systemState

  readonly property var battery: UPower.displayDevice
  readonly property int percentage: Math.round((battery?.percentage ?? 0) * 100)
  readonly property bool charging: battery?.state === UPowerDeviceState.Charging
  readonly property bool panelOpen: panelHost.activeId === widgetId

  visible: battery?.isPresent ?? false
  contentComponent: Component {
    Row {
      spacing: 4

      BatteryIndicator {
        anchors.verticalCenter: parent.verticalCenter
        level: root.percentage / 100
        charging: root.charging
        surfaceColor: root.theme.surface
        indicatorColor: root.theme.text
        lowColor: root.theme.batteryLow
        accentColor: root.theme.accent
        lowThreshold: root.config.lowThreshold
      }

      Text {
        visible: root.config.showPercentage
        text: `${root.percentage}%`
        color: root.theme.text
        font.family: root.theme.fontMono
        font.pixelSize: root.theme.readoutFontSize
        font.weight: root.theme.fontWeight
        font.styleName: root.theme.fontStyle
      }
    }
  }
  tooltip: `${charging ? "Charging" : "Battery"}: ${percentage}%`
  tooltipSuppressed: panelOpen
  onPrimary: () => panelHost.toggle(widgetId, root, panelComponent)
  secondaryCommand: config.powerCommand

  Component {
    id: panelComponent

    PowerPanel {
      theme: root.theme
      config: root.config
      active: root.panelOpen
    }
  }
}
