import QtQuick

Rectangle {
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
  readonly property real pivotOffset: centerGroup.visibleExtent > 0
    ? startGroup.visibleExtent + centerGroup.visibleExtent / 2
    : visibleExtent / 2
  color: theme.surface
  border.color: theme.border
  border.width: theme.borderWidth
  radius: theme.radius

  implicitWidth: visibleExtent
  implicitHeight: theme.barThickness

  WidgetGroup {
    id: startGroup
    instances: root.before
    edge: root.edge
    barWindow: root.barWindow
    theme: root.theme
    systemState: root.systemState
    panelHost: root.panelHost

    x: 0
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

    x: startGroup.width
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

    x: startGroup.width + centerGroup.width
    y: 0
  }
}
