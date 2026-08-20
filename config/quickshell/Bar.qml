import QtQuick
import Quickshell
import Quickshell.Wayland
import "layout"
import "panels"

PanelWindow {
  id: root

  required property var shellConfig
  required property var theme
  required property var systemState

  readonly property int totalThickness: theme.barMarginScreen
    + barLayout.contentHeight
    + theme.barMarginContent
  readonly property real visibleExtent: totalThickness

  color: theme.windowSurface
  aboveWindows: true
  focusable: false
  exclusionMode: shellConfig.exclusive ? ExclusionMode.Normal : ExclusionMode.Ignore
  exclusiveZone: shellConfig.exclusive ? totalThickness : 0

  anchors.top: shellConfig.edge === "top"
  anchors.bottom: shellConfig.edge === "bottom"
  anchors.left: true
  anchors.right: true

  implicitHeight: totalThickness
  implicitWidth: 0

  WlrLayershell.namespace: "hyprkarl-quickshell-bar"
  WlrLayershell.layer: WlrLayer.Top

  FeaturePanelHost {
    id: panelHost
    barWindow: root
    edge: root.shellConfig.edge
    theme: root.theme
  }

  BarLayout {
    id: barLayout
    anchors.fill: parent
    barWindow: root
    shellConfig: root.shellConfig
    theme: root.theme
    systemState: root.systemState
    panelHost: panelHost
  }
}
