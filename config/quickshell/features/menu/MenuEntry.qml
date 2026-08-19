import QtQuick

Item {
  id: root

  required property var theme
  required property var entry
  property bool selected: false

  signal hovered()
  signal chosen()

  implicitHeight: label.implicitHeight
    + root.theme.menuEntryPadding * 2
    + root.theme.menuEntryMargin * 2

  Rectangle {
    anchors.fill: parent
    anchors.margins: root.theme.menuEntryMargin
    color: root.theme.menuBackground
    border.color: root.selected
      ? root.theme.menuAccent
      : "transparent"
    border.width: root.selected ? root.theme.menuSelectionBorderWidth : 0
    radius: root.theme.menuEntryRadius

    Rectangle {
      anchors.fill: parent
      color: root.theme.menuAccent
      opacity: root.selected ? root.theme.menuSelectionAccentOpacity : 0
      radius: root.theme.menuEntryRadius
    }

    Text {
      id: label

      anchors.fill: parent
      anchors.margins: root.theme.menuEntryPadding
      text: root.entry.icon
        ? root.entry.icon + " " + root.entry.label
        : root.entry.label
      color: root.theme.menuForeground
      font.family: root.theme.menuFont
      font.pixelSize: root.theme.menuFontSize
      font.weight: root.theme.menuFontWeight
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
    }
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
