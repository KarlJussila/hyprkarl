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

  implicitHeight: content.implicitHeight
    + root.theme.menuEntryPadding * 2
    + root.theme.menuEntryMargin * 2
  opacity: disabled ? 0.45 : 1

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

    Column {
      id: content

      anchors.fill: parent
      anchors.margins: root.theme.menuEntryPadding

      Text {
        width: parent.width
        text: root.checked
          ? "󰄬 " + root.entry.label
          : root.entry.icon
          ? root.entry.icon + " " + root.entry.label
          : root.entry.label
        color: root.theme.menuForeground
        font.family: root.theme.menuFont
        font.pixelSize: root.theme.menuFontSize
        font.weight: root.theme.menuFontWeight
        horizontalAlignment: root.textAlignment
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        visible: text.length > 0
        text: root.entry.searchDetail ?? ""
        color: root.theme.menuForeground
        opacity: 0.55
        font.family: root.theme.menuFont
        font.pixelSize: Math.max(10, root.theme.menuFontSize - 2)
        font.weight: root.theme.menuFontWeight
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
