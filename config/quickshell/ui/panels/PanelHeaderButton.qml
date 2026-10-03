import QtQuick
import "../navigation"

NavigationControl {
  id: root

  required property var theme
  property string icon: ""
  navigationSection: "header"

  implicitWidth: 24
  implicitHeight: 24

  Rectangle {
    anchors.fill: parent
    color: "transparent"
    border.color: root.current ? root.theme.panel.accent : "transparent"
    border.width: root.current ? root.theme.panel.selectionBorderWidth : 0
    radius: root.theme.panel.entryRadius

    Rectangle {
      anchors.fill: parent
      color: root.theme.panel.accent
      opacity: root.current ? root.theme.panel.selectionAccentOpacity : 0
      radius: parent.radius
    }
  }

  Text {
    anchors.centerIn: parent
    text: root.icon
    color: root.theme.panel.foreground
    font.family: root.theme.panel.font
    font.pixelSize: root.theme.panel.fontSize
    font.weight: root.theme.panel.fontWeight
  }
}
