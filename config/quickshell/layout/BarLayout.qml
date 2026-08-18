import QtQuick

Item {
  id: root

  required property var barWindow
  required property var shellConfig
  required property var theme
  required property var systemState
  required property var panelHost

  readonly property int islandY: shellConfig.edge === "top"
    ? theme.barMarginScreen
    : theme.barMarginContent

  Island {
    id: startIsland
    instances: root.shellConfig.start
    side: "start"
    edge: root.shellConfig.edge
    barWindow: root.barWindow
    theme: root.theme
    systemState: root.systemState
    panelHost: root.panelHost

    x: root.theme.barMarginOuter
    y: root.islandY
  }

  CenterIsland {
    id: centerIsland
    before: root.shellConfig.centerBefore
    anchor: root.shellConfig.centerAnchorInstances
    after: root.shellConfig.centerAfter
    edge: root.shellConfig.edge
    barWindow: root.barWindow
    theme: root.theme
    systemState: root.systemState
    panelHost: root.panelHost

    x: parent.width / 2 - centerIsland.pivotOffset
    y: root.islandY
  }

  Island {
    id: endIsland
    instances: root.shellConfig.end
    side: "end"
    edge: root.shellConfig.edge
    barWindow: root.barWindow
    theme: root.theme
    systemState: root.systemState
    panelHost: root.panelHost

    x: parent.width - root.theme.barMarginOuter - width
    y: root.islandY
  }
}
