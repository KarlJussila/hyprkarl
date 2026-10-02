import QtQuick

Item {
  id: root

  required property var definition
  required property string edge
  required property bool showDivider
  required property var barWindow
  required property var theme
  required property var systemState
  required property var panelHost
  property real leadingBoundaryInset: 0
  property real trailingBoundaryInset: 0

  readonly property string widgetId: definition.id
  readonly property var loadedItem: loader.item
  readonly property int dividerExtent: showDivider && loadedItem?.visible ? theme.metrics.borderWidth : 0
  readonly property int mainPaddingOffset: loadedItem && ("hostMainPaddingOffset" in loadedItem)
    ? loadedItem.hostMainPaddingOffset
    : 0
  readonly property int mainPadding: Math.max(0, theme.bar.widgetPadding.main + mainPaddingOffset)
  property bool initialized: false

  implicitWidth: loadedItem?.visible
    ? loader.implicitWidth + dividerExtent + mainPadding * 2
    : 0
  implicitHeight: loadedItem?.visible
    ? loader.implicitHeight + theme.bar.widgetPadding.cross * 2
    : 0
  width: implicitWidth
  height: parent.height

  Rectangle {
    visible: root.dividerExtent > 0
    color: root.theme.palette.border
    width: root.dividerExtent
    height: parent.height
  }

  Loader {
    id: loader
    x: root.dividerExtent + root.leadingBoundaryInset
    width: implicitWidth + root.mainPadding * 2
      - root.leadingBoundaryInset - root.trailingBoundaryInset
    height: parent.height
  }

  Binding {
    target: loader.item
    property: "panelHost"
    value: root.panelHost
    when: loader.status === Loader.Ready
  }

  function loadWidget(): void {
    loader.source = ""
    const kind = root.definition.kind
    const source = kind[0].toUpperCase() + kind.slice(1) + "Widget.qml"
    loader.setSource(Qt.resolvedUrl(source), {
      widgetId: root.widgetId,
      config: root.definition,
      edge: root.edge,
      barWindow: root.barWindow,
      theme: root.theme,
      systemState: root.systemState,
      panelHost: root.panelHost
    })
  }

  onDefinitionChanged: {
    if (initialized) loadWidget()
  }

  Component.onCompleted: {
    initialized = true
    loadWidget()
  }
}
