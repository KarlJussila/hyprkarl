import QtQuick
import "../navigation"

NavigationControl {
  id: root

  required property var theme
  property string text: ""
  property string icon: ""
  property bool selected: false
  readonly property bool navigationSelected: root.selected
  readonly property bool highlighted: root.current || root.selected

  implicitWidth: parent?.width ?? label.implicitWidth + root.theme.panel.entryPadding * 2
  implicitHeight: 34

  Rectangle {
    anchors.fill: parent
    color: "transparent"
    border.color: root.highlighted ? root.theme.panel.accent : root.theme.panel.border
    border.width: root.theme.panel.selectionBorderWidth
    radius: root.theme.panel.entryRadius

    Rectangle {
      anchors.fill: parent
      color: root.theme.panel.accent
      opacity: root.current ? root.theme.panel.selectionAccentOpacity : 0
      radius: parent.radius
    }
  }

  Text {
    id: label

    anchors.centerIn: parent
    text: root.icon.length > 0 ? `${root.icon}  ${root.text}` : root.text
    color: root.selected ? root.theme.panel.accent : root.theme.panel.foreground
    font.family: root.theme.panel.font
    font.pixelSize: root.theme.panel.fontSize
    font.weight: root.theme.panel.fontWeight
  }
}
