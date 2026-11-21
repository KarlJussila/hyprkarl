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
    ? surface.contentLeft + content.implicitWidth + surface.contentRight
    : 0
  implicitHeight: Math.max(theme.bar.minimumThickness,
    surface.contentTop + content.implicitHeight + surface.contentBottom)

  // Hidden widgets take no space, so only a visible neighbor earns a divider.
  function visibleBefore(index: int): bool {
    for (let i = 0; i < index; i++)
      if (repeater.itemAt(i)?.loadedItem?.visible) return true
    return false
  }

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
    x: surface.contentLeft
    y: surface.contentTop
    width: implicitWidth
    height: parent.height - surface.contentTop - surface.contentBottom

    Repeater {
      id: repeater
      model: root.instances

      WidgetHost {
        required property int index
        required property var modelData

        definition: modelData
        edge: root.edge
        showDivider: root.theme.bar.showDividers && root.visibleBefore(index)
        barWindow: root.barWindow
        theme: root.theme
        systemState: root.systemState
        panelHost: root.panelHost
      }
    }
  }
}
