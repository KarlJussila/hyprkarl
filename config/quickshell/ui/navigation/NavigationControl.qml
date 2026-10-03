import QtQuick

// A control that panel and modal keyboard navigation can reach. Hovering or
// pressing it selects it; Return, Enter, or Space runs its action.
Item {
  id: root

  property string navigationSection: "main"
  property var action: null
  readonly property bool current: NavigationState.currentItem === root

  activeFocusOnTab: enabled && action !== null

  MouseArea {
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
