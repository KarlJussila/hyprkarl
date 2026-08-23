pragma ComponentBehavior: Bound

import QtQuick
import "../../components"

Item {
  id: root

  required property var theme
  property string text: ""
  property bool accent: false
  property string navigationSection: "footer"
  property var action: null
  readonly property bool current: NavigationState.currentItem === root
  readonly property bool highlighted: root.current

  activeFocusOnTab: enabled && action !== null
  implicitWidth: label.implicitWidth + root.theme.menuEntryPadding * 4
  implicitHeight: 34
  opacity: enabled ? 1 : 0.45

  Rectangle {
    anchors.fill: parent
    color: root.accent ? root.theme.menuAccent : "transparent"
    border.color: root.current && root.accent
      ? root.theme.menuForeground
      : root.highlighted || root.accent
        ? root.theme.menuAccent
        : root.theme.menuBorder
    border.width: root.theme.menuSelectionBorderWidth
    radius: root.theme.menuEntryRadius

    Rectangle {
      anchors.fill: parent
      color: root.theme.menuAccent
      opacity: !root.accent && root.current
        ? root.theme.menuSelectionAccentOpacity
        : 0
      radius: parent.radius
    }
  }

  Text {
    id: label

    anchors.centerIn: parent
    text: root.text
    color: root.accent ? root.theme.menuBackground : root.theme.menuForeground
    font.family: root.theme.menuFont
    font.pixelSize: root.theme.menuFontSize
    font.weight: root.theme.menuFontWeight
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled && root.action !== null
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onPressed: NavigationState.usePointer(root, root.navigationSection)
    onClicked: root.action()
  }

  HoverHandler {
    enabled: root.enabled && root.action !== null
    blocking: false
    onPointChanged: if (hovered) NavigationState.usePointer(root, root.navigationSection)
  }

  Keys.onPressed: event => {
    if (!root.action
        || (event.key !== Qt.Key_Return
          && event.key !== Qt.Key_Enter
          && event.key !== Qt.Key_Space)) return
    NavigationState.useKeyboard(root, Qt.ShortcutFocusReason, root.navigationSection)
    root.action()
    event.accepted = true
  }
}
