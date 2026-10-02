import QtQuick

Item {
  id: root

  required property var before
  required property var anchor
  required property var after
  required property string edge
  required property var barWindow
  required property var theme
  required property var systemState
  required property var panelHost

  readonly property real visibleExtent: startGroup.visibleExtent + centerGroup.visibleExtent + endGroup.visibleExtent
  readonly property bool hasContent: visibleExtent > 0
  readonly property real pivotOffset: hasContent
    ? surface.leftInset + (centerGroup.visibleExtent > 0
      ? startGroup.visibleExtent + centerGroup.visibleExtent / 2
      : visibleExtent / 2)
    : 0

  implicitWidth: hasContent
    ? surface.leftInset + visibleExtent + surface.rightInset
    : 0
  implicitHeight: Math.max(
    theme.bar.minimumThickness,
    startGroup.implicitHeight,
    centerGroup.implicitHeight,
    endGroup.implicitHeight
  )

  IslandSurface {
    id: surface
    anchors.fill: parent
    edge: root.edge
    leftRole: "inner"
    rightRole: "inner"
    theme: root.theme
  }

  WidgetGroup {
    id: startGroup
    instances: root.before
    edge: root.edge
    barWindow: root.barWindow
    theme: root.theme
    systemState: root.systemState
    panelHost: root.panelHost

    x: surface.leftInset
    y: 0
  }

  WidgetGroup {
    id: centerGroup
    instances: root.anchor
    edge: root.edge
    barWindow: root.barWindow
    theme: root.theme
    systemState: root.systemState
    panelHost: root.panelHost
    leadingDivider: startGroup.visibleExtent > 0

    x: surface.leftInset + startGroup.width
    y: 0
  }

  WidgetGroup {
    id: endGroup
    instances: root.after
    edge: root.edge
    barWindow: root.barWindow
    theme: root.theme
    systemState: root.systemState
    panelHost: root.panelHost
    leadingDivider: centerGroup.visibleExtent > 0 || startGroup.visibleExtent > 0

    x: surface.leftInset + startGroup.width + centerGroup.width
    y: 0
  }
}
