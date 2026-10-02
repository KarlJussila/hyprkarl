import QtQuick

Item {
  id: root

  required property var barWindow
  required property var shellConfig
  required property var theme
  required property var systemState
  required property var panelHost

  readonly property int islandY: shellConfig.bar.edge === "top"
    ? theme.barMarginScreen
    : theme.barMarginContent
  readonly property real contentHeight: Math.max(
    startIsland.implicitHeight,
    centerIsland.implicitHeight,
    endIsland.implicitHeight
  )

  implicitHeight: contentHeight

  Island {
    id: startIsland
    instances: root.shellConfig.bar.layout.start
    side: "start"
    edge: root.shellConfig.bar.edge
    barWindow: root.barWindow
    theme: root.theme
    systemState: root.systemState
    panelHost: root.panelHost

    x: root.theme.barMarginOuter
    y: root.islandY
    height: root.contentHeight
  }

  CenterIsland {
    id: centerIsland
    before: root.shellConfig.bar.layout.center.before
    anchor: root.shellConfig.bar.layout.center.anchor
      ? [root.shellConfig.bar.layout.center.anchor] : []
    after: root.shellConfig.bar.layout.center.after
    edge: root.shellConfig.bar.edge
    barWindow: root.barWindow
    theme: root.theme
    systemState: root.systemState
    panelHost: root.panelHost

    x: parent.width / 2 - centerIsland.pivotOffset
    y: root.islandY
    height: root.contentHeight
  }

  Island {
    id: endIsland
    instances: root.shellConfig.bar.layout.end
    side: "end"
    edge: root.shellConfig.bar.edge
    barWindow: root.barWindow
    theme: root.theme
    systemState: root.systemState
    panelHost: root.panelHost

    x: parent.width - root.theme.barMarginOuter - width
    y: root.islandY
    height: root.contentHeight
  }
}
