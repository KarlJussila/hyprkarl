pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "layout"

PanelWindow {
  id: root

  required property var shellConfig
  required property var theme
  required property var systemState
  required property bool screenshotActive

  readonly property var panelHost: panelHostLoader.item
  readonly property int totalThickness: theme.bar.margin.screen
    + barLayout.contentHeight
    + theme.bar.margin.content
  readonly property real visibleExtent: totalThickness

  color: theme.surfaces.window
  aboveWindows: true
  focusable: root.panelHost?.open ?? false
  exclusionMode: shellConfig.bar.exclusive ? ExclusionMode.Normal : ExclusionMode.Ignore
  exclusiveZone: shellConfig.bar.exclusive ? totalThickness : 0

  anchors.top: shellConfig.bar.edge === "top"
  anchors.bottom: shellConfig.bar.edge === "bottom"
  anchors.left: true
  anchors.right: true

  implicitHeight: totalThickness
  implicitWidth: 0

  WlrLayershell.namespace: "hyprkarl-quickshell-bar"
  WlrLayershell.layer: WlrLayer.Top

  contentItem {
    focus: root.panelHost?.open ?? false
    Keys.forwardTo: root.panelHost?.keyTargets ?? []
  }

  LazyLoader {
    id: panelHostLoader
    active: root.shellConfig.modules.panels

    PanelHost {
      barWindow: root
      edge: root.shellConfig.bar.edge
      theme: root.theme
      screenshotActive: root.screenshotActive
    }
  }

  BarLayout {
    id: barLayout
    anchors.fill: parent
    barWindow: root
    shellConfig: root.shellConfig
    theme: root.theme
    systemState: root.systemState
    panelHost: root.panelHost
  }
}
