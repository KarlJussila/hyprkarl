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

  readonly property string widgetId: definition.id
  readonly property var loadedItem: loader.item
  readonly property int dividerExtent: showDivider && loadedItem?.visible ? theme.borderWidth : 0
  readonly property int mainPaddingOffset: loadedItem && ("hostMainPaddingOffset" in loadedItem)
    ? loadedItem.hostMainPaddingOffset
    : 0
  readonly property int mainPadding: Math.max(0, theme.widgetMainPadding + mainPaddingOffset)
  property bool initialized: false

  implicitWidth: loadedItem?.visible
    ? loader.implicitWidth + dividerExtent + mainPadding * 2
    : 0
  implicitHeight: loadedItem?.visible
    ? loader.implicitHeight + theme.widgetCrossPadding * 2
    : 0
  width: implicitWidth
  height: parent.height

  Rectangle {
    visible: root.dividerExtent > 0
    color: root.theme.border
    width: root.dividerExtent
    height: parent.height
  }

  Loader {
    id: loader
    x: root.dividerExtent
    width: implicitWidth + root.mainPadding * 2
    height: parent.height
  }

  function loadWidget(): void {
    loader.source = ""
    loader.setSource(Qt.resolvedUrl(root.definition.kind + ".qml"), {
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
