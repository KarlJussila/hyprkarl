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

  Row {
    id: content
    anchors.fill: parent

    Repeater {
      model: root.instances

      WidgetHost {
        required property int index
        required property var modelData

        definition: modelData
        edge: root.edge
        showDivider: root.theme.showDividers && (index > 0 || root.leadingDivider)
        barWindow: root.barWindow
        theme: root.theme
        systemState: root.systemState
        panelHost: root.panelHost
      }
    }
  }
}
