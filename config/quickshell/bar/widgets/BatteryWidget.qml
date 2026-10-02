pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower
import "../../modules/power"
import "../../ui/controls"
import "../../ui/indicators"

ShellButton {
  id: root

  required property string widgetId
  required property var config
  required property var systemState

  readonly property var battery: UPower.displayDevice
  readonly property int percentage: Math.round((battery?.percentage ?? 0) * 100)
  readonly property string percentageText: percentage >= 100 ? "MAX" : percentage + "%"
  readonly property bool charging: battery?.state === UPowerDeviceState.Charging
  readonly property bool panelOpen: panelHost
    ? panelHost.activeId === widgetId
    : false

  visible: battery?.isPresent ?? false
  contentComponent: Component {
    Row {
      spacing: 4

      BatteryIndicator {
        anchors.verticalCenter: parent.verticalCenter
        level: root.percentage / 100
        charging: root.charging
        surfaceColor: root.theme.surfaces.bar
        indicatorColor: root.theme.palette.foreground
        lowColor: root.theme.palette.warning
        accentColor: root.theme.palette.accent
        lowThreshold: root.config.lowThreshold
      }

      Text {
        visible: root.config.showPercentage
        text: root.percentageText
        color: root.theme.palette.foreground
        font.family: root.theme.typography.monoFamily
        font.pixelSize: root.theme.typography.readoutSize
        font.weight: root.theme.typography.weight
        font.styleName: root.theme.typography.style
      }
    }
  }
  tooltip: `${charging ? "Charging" : "Battery"}: ${percentage}%`
  tooltipSuppressed: panelOpen
  onPrimary: panelHost
    ? () => panelHost.toggle(widgetId, root, panelComponent)
    : null
  secondaryCommand: config.powerCommand

  Component {
    id: panelComponent

    PowerPanel {
      theme: root.theme
      config: root.config
      active: root.panelOpen
      onExternalCommandRequested: command => root.launchPanelCommand(command)
    }
  }
}
