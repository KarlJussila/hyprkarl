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
    ? surface.contentLeft + (centerGroup.visibleExtent > 0
      ? startGroup.visibleExtent + centerGroup.visibleExtent / 2
      : visibleExtent / 2)
    : 0

  implicitWidth: hasContent
    ? surface.contentLeft + visibleExtent + surface.contentRight
    : 0
  implicitHeight: Math.max(
    theme.bar.minimumThickness,
    surface.contentTop + Math.max(
      startGroup.implicitHeight,
      centerGroup.implicitHeight,
      endGroup.implicitHeight
    ) + surface.contentBottom
  )
  readonly property real groupHeight: height - surface.contentTop - surface.contentBottom

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

    x: surface.contentLeft
    y: surface.contentTop
    height: root.groupHeight
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

    x: surface.contentLeft + startGroup.width
    y: surface.contentTop
    height: root.groupHeight
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

    x: surface.contentLeft + startGroup.width + centerGroup.width
    y: surface.contentTop
    height: root.groupHeight
  }
}
