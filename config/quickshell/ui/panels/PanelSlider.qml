import QtQuick
import "../navigation"

Item {
  id: root

  required property var theme
  property real value: 0
  property real stepSize: 0.05
  property string navigationSection: "main"
  signal edited(real value)
  readonly property bool current: NavigationState.currentItem === root

  activeFocusOnTab: enabled
  implicitWidth: parent?.width ?? 180
  implicitHeight: 24

  function setFromPosition(x: real): void {
    edited(Math.max(0, Math.min(1, x / track.width)))
  }

  function step(direction: int): void {
    edited(Math.max(0, Math.min(1, value + stepSize * direction)))
  }

  Rectangle {
    id: track

    anchors.left: parent.left
    anchors.right: valueLabel.left
    anchors.rightMargin: root.theme.panel.entryPadding
    anchors.verticalCenter: parent.verticalCenter
    height: 6
    radius: 3
    color: root.theme.panel.border

    Rectangle {
      width: parent.width * Math.max(0, Math.min(1, root.value))
      height: parent.height
      radius: parent.radius
      color: root.theme.panel.accent
    }

    Rectangle {
      x: Math.max(0, Math.min(parent.width - width, parent.width * root.value - width / 2))
      anchors.verticalCenter: parent.verticalCenter
      width: root.current ? 12 : 10
      height: width
      radius: width / 2
      color: root.theme.panel.foreground
    }

    MouseArea {
      anchors.fill: parent
      anchors.topMargin: -8
      anchors.bottomMargin: -8
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onPressed: event => {
        NavigationState.usePointer(root, root.navigationSection)
        root.setFromPosition(event.x)
      }
      onPositionChanged: event => {
        if (pressed) root.setFromPosition(event.x)
      }
    }
  }

  Text {
    id: valueLabel

    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: 38
    text: `${Math.round(root.value * 100)}%`
    color: root.current
      ? root.theme.panel.accent
      : root.theme.panel.foreground
    font.family: root.theme.typography.monoFamily
    font.pixelSize: root.theme.typography.readoutSize
    horizontalAlignment: Text.AlignRight
  }

  Keys.onLeftPressed: event => {
    NavigationState.useKeyboard(root, Qt.ShortcutFocusReason, root.navigationSection)
    root.step(-1)
    event.accepted = true
  }
  Keys.onRightPressed: event => {
    NavigationState.useKeyboard(root, Qt.ShortcutFocusReason, root.navigationSection)
    root.step(1)
    event.accepted = true
  }
  Keys.onPressed: event => {
    if (event.key === Qt.Key_H) root.step(-1)
    else if (event.key === Qt.Key_L) root.step(1)
    else return
    NavigationState.useKeyboard(root, Qt.ShortcutFocusReason, root.navigationSection)
    event.accepted = true
  }

  HoverHandler {
    enabled: root.enabled
    blocking: false
    onPointChanged: if (hovered) NavigationState.usePointer(root, root.navigationSection)
  }
}
