import QtQuick

Item {
  id: root

  required property var barWindow
  required property var shellConfig
  required property var theme
  required property var systemState
  required property var panelHost

  Island {
    id: startIsland
    instances: root.shellConfig.start
    edge: root.shellConfig.edge
    barWindow: root.barWindow
    theme: root.theme
    systemState: root.systemState
    panelHost: root.panelHost

    x: 0
    y: 0
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
    y: 0
  }

  Island {
    id: endIsland
    instances: root.shellConfig.end
    edge: root.shellConfig.edge
    barWindow: root.barWindow
    theme: root.theme
    systemState: root.systemState
    panelHost: root.panelHost

    x: parent.width - width
    y: 0
  }
}
