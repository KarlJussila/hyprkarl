pragma ComponentBehavior: Bound

import QtQuick
import "../navigation"

NavigationControl {
  id: root

  required property var theme
  property string text: ""
  property bool accent: false
  navigationSection: "footer"

  implicitWidth: label.implicitWidth + root.theme.menu.entryPadding * 4
  implicitHeight: 34
  opacity: enabled ? 1 : 0.45

  Rectangle {
    anchors.fill: parent
    color: root.accent ? root.theme.menu.accent : "transparent"
    border.color: root.current && root.accent
      ? root.theme.menu.foreground
      : root.current || root.accent
        ? root.theme.menu.accent
        : root.theme.menu.border
    border.width: root.theme.menu.selectionBorderWidth
    radius: root.theme.menu.entryRadius

    Rectangle {
      anchors.fill: parent
      color: root.theme.menu.accent
      opacity: !root.accent && root.current
        ? root.theme.menu.selectionAccentOpacity
        : 0
      radius: parent.radius
    }
  }

  Text {
    id: label

    anchors.centerIn: parent
    text: root.text
    color: root.accent ? root.theme.menu.background : root.theme.menu.foreground
    font.family: root.theme.menu.font
    font.pixelSize: root.theme.menu.fontSize
    font.weight: root.theme.menu.fontWeight
  }
}
