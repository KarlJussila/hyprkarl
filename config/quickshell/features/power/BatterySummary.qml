import QtQuick
import Quickshell.Services.UPower
import "../../components"

Rectangle {
  id: root

  required property var theme
  required property var battery
  required property var config
  property string status: ""
  property string estimate: ""
  property string metrics: ""

  implicitWidth: parent?.width ?? 0
  implicitHeight: metrics.length > 0 ? 86 : 66
  color: theme.background
  border.color: theme.border
  border.width: theme.borderWidth
  radius: theme.radius

  Item {
    id: indicatorArea

    anchors.left: parent.left
    anchors.leftMargin: root.theme.controlPadding * 2
    anchors.top: parent.top
    anchors.topMargin: 16
    width: 38
    height: 24

    BatteryIndicator {
      anchors.centerIn: parent
      scale: 1.8
      level: root.battery?.percentage ?? 0
      charging: root.battery?.state === UPowerDeviceState.Charging
      surfaceColor: root.theme.background
      indicatorColor: root.theme.text
      lowColor: root.theme.batteryLow
      accentColor: root.theme.accent
      lowThreshold: root.config.lowThreshold
    }
  }

  Text {
    id: percentageLabel

    anchors.left: indicatorArea.right
    anchors.leftMargin: root.theme.controlPadding
    anchors.verticalCenter: indicatorArea.verticalCenter
    text: `${Math.round((root.battery?.percentage ?? 0) * 100)}%`
    color: root.theme.text
    font.family: root.theme.fontMono
    font.pixelSize: root.theme.fontSize + 8
    font.weight: root.theme.fontWeight
    font.styleName: root.theme.fontStyle
  }

  Text {
    anchors.left: percentageLabel.right
    anchors.leftMargin: root.theme.controlPadding
    anchors.right: parent.right
    anchors.rightMargin: root.theme.controlPadding * 2
    anchors.verticalCenter: indicatorArea.verticalCenter
    text: root.estimate.length > 0 ? `${root.status} · ${root.estimate}` : root.status
    color: root.theme.text
    opacity: 0.7
    font.family: root.theme.fontUi
    font.pixelSize: root.theme.readoutFontSize
    horizontalAlignment: Text.AlignRight
    elide: Text.ElideRight
  }

  Text {
    anchors.left: parent.left
    anchors.leftMargin: root.theme.controlPadding * 2
    anchors.right: parent.right
    anchors.rightMargin: root.theme.controlPadding * 2
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 10
    visible: root.metrics.length > 0
    text: root.metrics
    color: root.theme.text
    opacity: 0.58
    font.family: root.theme.fontMono
    font.pixelSize: root.theme.readoutFontSize
    elide: Text.ElideRight
  }
}
