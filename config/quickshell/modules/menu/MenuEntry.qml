import QtQuick
import Quickshell.Io

Item {
  id: root

  required property var theme
  required property var entry
  required property int textAlignment
  required property int refreshToken
  property bool selected: false
  property bool checked: false
  readonly property bool disabled: entry.disabled === true

  signal pointerMoved(real sceneX, real sceneY)
  signal chosen()

  function refreshChecked(): void {
    checked = false
    if (entry.checkedCommand) checkProcess.running = true
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

  implicitHeight: content.implicitHeight
    + root.theme.menu.entryPadding * 2
    + root.theme.menu.entryMargin * 2
  opacity: disabled ? 0.45 : 1

  Rectangle {
    anchors.fill: parent
    anchors.margins: root.theme.menu.entryMargin
    color: root.theme.menu.background
    border.color: root.selected
      ? root.theme.menu.accent
      : "transparent"
    border.width: root.selected ? root.theme.menu.selectionBorderWidth : 0
    radius: root.theme.menu.entryRadius

    Rectangle {
      anchors.fill: parent
      color: root.theme.menu.accent
      opacity: root.selected ? root.theme.menu.selectionAccentOpacity : 0
      radius: root.theme.menu.entryRadius
    }

    Column {
      id: content

      anchors.fill: parent
      anchors.margins: root.theme.menu.entryPadding

      Text {
        width: parent.width
        text: root.checked
          ? "󰄬 " + root.entry.label
          : root.entry.icon
          ? root.entry.icon + " " + root.entry.label
          : root.entry.label
        color: root.theme.menu.foreground
        font.family: root.theme.menu.font
        font.pixelSize: root.theme.menu.fontSize
        font.weight: root.theme.menu.fontWeight
        horizontalAlignment: root.textAlignment
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        visible: text.length > 0
        text: root.entry.searchDetail ?? ""
        color: root.theme.menu.foreground
        opacity: 0.55
        font.family: root.theme.menu.font
        font.pixelSize: Math.max(10, root.theme.menu.fontSize - 2)
        font.weight: root.theme.menu.fontWeight
        horizontalAlignment: root.textAlignment
        elide: Text.ElideRight
      }
    }
  }

  HoverHandler {
    id: hover

    cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
    onPointChanged: if (!root.disabled) root.pointerMoved(
      point.scenePosition.x, point.scenePosition.y)
  }

  TapHandler {
    enabled: !root.disabled
    onTapped: root.chosen()
  }
}
