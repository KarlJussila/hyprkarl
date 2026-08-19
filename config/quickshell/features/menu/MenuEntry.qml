import QtQuick

Item {
  id: root

  required property var theme
  required property var entry
  property bool selected: false

  signal hovered()
  signal chosen()

  implicitHeight: 42

  Rectangle {
    anchors.fill: parent
    color: root.theme.accent
    opacity: root.selected ? 0.24 : mouse.containsMouse ? 0.16 : 0
    radius: root.theme.radius
  }

  Text {
    id: iconLabel

    anchors.left: parent.left
    anchors.leftMargin: root.theme.controlPadding
    anchors.verticalCenter: parent.verticalCenter
    width: 24
    text: root.entry.icon ?? ""
    color: root.selected ? root.theme.accent : root.theme.text
    font.family: root.theme.fontUi
    font.pixelSize: root.theme.fontSize
    horizontalAlignment: Text.AlignHCenter
  }

  Text {
    anchors.left: iconLabel.right
    anchors.leftMargin: root.theme.controlPadding
    anchors.right: disclosure.left
    anchors.rightMargin: root.theme.controlPadding
    anchors.verticalCenter: parent.verticalCenter
    text: root.entry.label
    color: root.theme.text
    font.family: root.theme.fontUi
    font.pixelSize: root.theme.fontSize
    font.weight: root.selected ? root.theme.fontWeight : Font.Normal
    elide: Text.ElideRight
  }

  Text {
    id: disclosure

    anchors.right: parent.right
    anchors.rightMargin: root.theme.controlPadding
    anchors.verticalCenter: parent.verticalCenter
    width: 16
    text: root.entry.action.type === "menu" ? "›" : ""
    color: root.theme.text
    opacity: 0.65
    font.family: root.theme.fontUi
    font.pixelSize: root.theme.fontSize + 2
    horizontalAlignment: Text.AlignHCenter
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: root.hovered()
    onClicked: root.chosen()
  }
}
