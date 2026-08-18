pragma ComponentBehavior: Bound

import QtQuick
import "../widgets"

Rectangle {
  id: root

  required property var instances
  required property string edge
  required property var barWindow
  required property var theme
  required property var systemState
  required property var panelHost

  color: theme.surface
  border.color: theme.border
  border.width: theme.borderWidth
  radius: theme.radius

  implicitWidth: content.implicitWidth
  implicitHeight: theme.barThickness

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
        showDivider: root.theme.showDividers && index > 0
        barWindow: root.barWindow
        theme: root.theme
        systemState: root.systemState
        panelHost: root.panelHost
      }
    }
  }
}
