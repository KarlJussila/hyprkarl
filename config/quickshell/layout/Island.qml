pragma ComponentBehavior: Bound

import QtQuick
import "../widgets"

Item {
  id: root

  required property var instances
  required property string side
  required property string edge
  required property var barWindow
  required property var theme
  required property var systemState
  required property var panelHost

  readonly property string leftRole: side === "start" ? "outer" : "inner"
  readonly property string rightRole: side === "start" ? "inner" : "outer"
  readonly property bool hasContent: content.implicitWidth > 0

  implicitWidth: hasContent
    ? surface.leftInset + content.implicitWidth + surface.rightInset
    : 0
  implicitHeight: theme.barThickness

  IslandSurface {
    id: surface
    anchors.fill: parent
    edge: root.edge
    leftRole: root.leftRole
    rightRole: root.rightRole
    theme: root.theme
  }

  Row {
    id: content
    x: surface.leftInset
    width: implicitWidth
    height: parent.height

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
