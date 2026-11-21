pragma ComponentBehavior: Bound

import QtQuick
import "../widgets"

Item {
  id: root

  required property var instances
  required property string edge
  required property var barWindow
  required property var theme
  required property var systemState
  required property var panelHost
  property bool leadingDivider: false

  readonly property real visibleExtent: content.implicitWidth

  width: visibleExtent
  implicitHeight: content.implicitHeight
  height: parent.height

  // Hidden widgets take no space, so only a visible neighbor earns a divider.
  function visibleBefore(index: int): bool {
    for (let i = 0; i < index; i++)
      if (repeater.itemAt(i)?.loadedItem?.visible) return true
    return false
  }

  Row {
    id: content
    anchors.fill: parent

    Repeater {
      id: repeater
      model: root.instances

      WidgetHost {
        required property int index
        required property var modelData

        definition: modelData
        edge: root.edge
        showDivider: root.theme.bar.showDividers && (root.leadingDivider || root.visibleBefore(index))
        barWindow: root.barWindow
        theme: root.theme
        systemState: root.systemState
        panelHost: root.panelHost
      }
    }
  }
}
