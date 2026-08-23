import QtQuick

Item {
  id: root

  required property var theme
  property string icon: ""
  property string navigationSection: "header"
  property var action: null
  readonly property bool current: NavigationState.currentItem === root
  readonly property bool highlighted: root.current

  activeFocusOnTab: visible && enabled && action !== null
  implicitWidth: 24
  implicitHeight: 24

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
    text: root.icon
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
    onPressed: NavigationState.usePointer(root, root.navigationSection)
    onClicked: root.action()
  }

  HoverHandler {
    enabled: root.enabled && root.action !== null
    blocking: false
    onPointChanged: if (hovered) NavigationState.usePointer(root, root.navigationSection)
  }

  Keys.onPressed: event => {
    if (!root.action || (event.key !== Qt.Key_Return
        && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space)) return
    NavigationState.useKeyboard(root, Qt.ShortcutFocusReason, root.navigationSection)
    root.action()
    event.accepted = true
  }
}
