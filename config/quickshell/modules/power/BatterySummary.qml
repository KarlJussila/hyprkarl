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
  implicitHeight: content.implicitHeight + root.theme.panelEntryPadding * 2
  color: theme.panelBackground
  border.color: theme.panelBorder
  border.width: theme.panelSelectionBorderWidth
  radius: theme.panelEntryRadius

  Text {
    id: percentageMeasure

    visible: false
    text: "MAX"
    font.family: root.theme.monoFontFamily
    font.pixelSize: root.theme.panelFontSize + 8
    font.weight: root.theme.panelFontWeight
    font.styleName: root.theme.fontStyle
  }

  Column {
    id: content

    anchors.left: parent.left
    anchors.leftMargin: root.theme.panelEntryPadding * 2
    anchors.right: parent.right
    anchors.rightMargin: root.theme.panelEntryPadding * 2
    anchors.verticalCenter: parent.verticalCenter
    spacing: root.theme.panelEntryPadding

    Item {
      width: parent.width
      height: Math.max(percentageLabel.implicitHeight, statusLabel.implicitHeight)

      Text {
        id: percentageLabel

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: percentageMeasure.implicitWidth
        text: root.percentageText
        color: root.theme.panelForeground
        font.family: root.theme.monoFontFamily
        font.pixelSize: root.theme.panelFontSize + 8
        font.weight: root.theme.panelFontWeight
        font.styleName: root.theme.fontStyle
        horizontalAlignment: Text.AlignHCenter
      }

      Text {
        id: statusLabel

        anchors.left: percentageLabel.right
        anchors.leftMargin: root.theme.panelEntryPadding
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.estimate.length > 0 ? `${root.status} · ${root.estimate}` : root.status
        color: root.theme.panelForeground
        opacity: 0.7
        font.family: root.theme.panelFont
        font.pixelSize: root.theme.readoutFontSize
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
        width: percentageLabel.implicitWidth
        height: parent.height

        BatteryIndicator {
          anchors.centerIn: parent
          nativeScale: indicatorArea.width / 18
          level: root.battery?.percentage ?? 0
          charging: root.battery?.state === UPowerDeviceState.Charging
          surfaceColor: root.theme.panelBackground
          indicatorColor: root.theme.panelForeground
          lowColor: root.theme.warning
          accentColor: root.theme.panelAccent
          lowThreshold: root.config.lowThreshold
        }
      }

      Text {
        anchors.left: indicatorArea.right
        anchors.leftMargin: root.theme.panelEntryPadding
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.metrics.length > 0
        text: root.metrics
        color: root.theme.panelForeground
        opacity: 0.58
        font.family: root.theme.monoFontFamily
        font.pixelSize: root.theme.readoutFontSize
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
      }
    }
  }
}
