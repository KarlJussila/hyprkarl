import QtQuick
import Quickshell.Io

Item {
  id: root

  required property var theme
  required property var entry
  required property int refreshToken
  property bool selected: false
  property bool checked: false

  signal hovered()
  signal chosen()

  function refreshChecked(): void {
    checked = false
    if (typeof entry.checkedCommand === "string") checkProcess.running = true
  }

  onRefreshTokenChanged: refreshChecked()
  Component.onCompleted: refreshChecked()

  Process {
    id: checkProcess

    command: ["bash", "-c",
      `${root.entry.checkedCommand} >/dev/null 2>&1; printf '%s' $?`]
    stdout: StdioCollector {
      onStreamFinished: root.checked = Number(text.trim()) === 0
    }
  }

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
      text: root.checked
        ? "󰄬 " + root.entry.label
        : root.entry.icon
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
