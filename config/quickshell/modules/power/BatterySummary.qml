import QtQuick
import Quickshell.Services.UPower
import "../../ui/indicators"

Rectangle {
  id: root

  required property var theme
  required property var battery
  required property var config
  property string status: ""
  property string estimate: ""
  property string metrics: ""
  readonly property int percentage: Math.round((battery?.percentage ?? 0) * 100)
  readonly property string percentageText: percentage >= 100 ? "MAX" : percentage + "%"

  implicitWidth: parent?.width ?? 0
  implicitHeight: content.implicitHeight + root.theme.panel.entryPadding * 2
  color: theme.panel.background
  border.color: theme.panel.border
  border.width: theme.panel.selectionBorderWidth
  radius: theme.panel.entryRadius

  Text {
    id: percentageMeasure

    visible: false
    text: "MAX"
    font.family: root.theme.typography.monoFamily
    font.pixelSize: root.theme.panel.fontSize + 8
    font.weight: root.theme.panel.fontWeight
    font.styleName: root.theme.typography.style
  }

  Column {
    id: content

    anchors.left: parent.left
    anchors.leftMargin: root.theme.panel.entryPadding * 2
    anchors.right: parent.right
    anchors.rightMargin: root.theme.panel.entryPadding * 2
    anchors.verticalCenter: parent.verticalCenter
    spacing: root.theme.panel.entryPadding

    Item {
      width: parent.width
      height: Math.max(percentageLabel.implicitHeight, statusLabel.implicitHeight)

      Text {
        id: percentageLabel

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: percentageMeasure.implicitWidth
        text: root.percentageText
        color: root.theme.panel.foreground
        font.family: root.theme.typography.monoFamily
        font.pixelSize: root.theme.panel.fontSize + 8
        font.weight: root.theme.panel.fontWeight
        font.styleName: root.theme.typography.style
        horizontalAlignment: Text.AlignHCenter
      }

      Text {
        id: statusLabel

        anchors.left: percentageLabel.right
        anchors.leftMargin: root.theme.panel.entryPadding
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.estimate.length > 0 ? `${root.status} · ${root.estimate}` : root.status
        color: root.theme.panel.foreground
        opacity: 0.7
        font.family: root.theme.panel.font
        font.pixelSize: root.theme.typography.readoutSize
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
      }
    }

    Item {
      width: parent.width
      height: 24

      Item {
        id: indicatorArea

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: percentageLabel.width
        height: parent.height

        BatteryIndicator {
          anchors.centerIn: parent
          nativeScale: indicatorArea.width / 18
          level: root.battery?.percentage ?? 0
          charging: root.battery?.state === UPowerDeviceState.Charging
          surfaceColor: root.theme.panel.background
          indicatorColor: root.theme.panel.foreground
          lowColor: root.theme.palette.warning
          accentColor: root.theme.panel.accent
          lowThreshold: root.config.lowThreshold
        }
      }

      Text {
        anchors.left: indicatorArea.right
        anchors.leftMargin: root.theme.panel.entryPadding
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.metrics.length > 0
        text: root.metrics
        color: root.theme.panel.foreground
        opacity: 0.58
        font.family: root.theme.typography.monoFamily
        font.pixelSize: root.theme.typography.readoutSize
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
      }
    }
  }
}
