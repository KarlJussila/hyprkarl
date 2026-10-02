import QtQuick
import "../../ui/navigation" as Navigation

Item {
  id: root

  required property var theme
  property string text: ""
  property string navigationSection: "main"
  property var action: null
  readonly property bool current: Navigation.NavigationState.currentItem === root
  readonly property bool highlighted: root.current

  activeFocusOnTab: enabled && action !== null
  implicitWidth: 34
  implicitHeight: 34

  Rectangle {
    anchors.fill: parent
    color: "transparent"
    border.color: root.highlighted ? root.theme.panel.accent : "transparent"
    border.width: root.highlighted ? root.theme.panel.selectionBorderWidth : 0
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
    text: root.text
    color: root.theme.panel.foreground
    font.family: root.theme.panel.font
    font.pixelSize: root.theme.panel.fontSize
    font.weight: root.theme.panel.fontWeight
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled && root.action !== null
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onPressed: Navigation.NavigationState.usePointer(root, root.navigationSection)
    onClicked: root.action()
  }

  HoverHandler {
    enabled: root.enabled && root.action !== null
    blocking: false
    onPointChanged: if (hovered) Navigation.NavigationState.usePointer(root, root.navigationSection)
  }

  Keys.onPressed: event => {
    if (!root.action || (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space)) return
    Navigation.NavigationState.useKeyboard(root, Qt.ShortcutFocusReason, root.navigationSection)
    root.action()
    event.accepted = true
  }
}
