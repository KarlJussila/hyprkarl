import QtQuick
import "../../components" as Components

Item {
  id: root

  required property var theme
  property string text: ""
  property string navigationSection: "main"
  property var action: null
  readonly property bool current: Components.NavigationState.currentItem === root
  readonly property bool highlighted: root.current

  activeFocusOnTab: enabled && action !== null
  implicitWidth: 34
  implicitHeight: 34

  Rectangle {
    anchors.fill: parent
    color: "transparent"
    border.color: root.highlighted ? root.theme.panelAccent : "transparent"
    border.width: root.highlighted ? root.theme.panelSelectionBorderWidth : 0
    radius: root.theme.panelEntryRadius

    Rectangle {
      anchors.fill: parent
      color: root.theme.panelAccent
      opacity: root.current ? root.theme.panelSelectionAccentOpacity : 0
      radius: parent.radius
    }
  }

  Text {
    anchors.centerIn: parent
    text: root.text
    color: root.theme.panelForeground
    font.family: root.theme.panelFont
    font.pixelSize: root.theme.panelFontSize
    font.weight: root.theme.panelFontWeight
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled && root.action !== null
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onPressed: Components.NavigationState.usePointer(root, root.navigationSection)
    onClicked: root.action()
  }

  HoverHandler {
    enabled: root.enabled && root.action !== null
    blocking: false
    onPointChanged: if (hovered) Components.NavigationState.usePointer(root, root.navigationSection)
  }

  Keys.onPressed: event => {
    if (!root.action || (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space)) return
    Components.NavigationState.useKeyboard(root, Qt.ShortcutFocusReason, root.navigationSection)
    root.action()
    event.accepted = true
  }
}
