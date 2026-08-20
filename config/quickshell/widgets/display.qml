pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../components"
import "../features/display"

ShellButton {
  id: root

  required property string widgetId
  required property var config
  required property var systemState

  readonly property bool panelOpen: panelHost.activeId === widgetId

  text: Quickshell.screens.length > 1 ? "󰍺" : "󰍹"
  tooltip: "Display"
  tooltipSuppressed: panelOpen
  onPrimary: () => panelHost.toggle(widgetId, root, panelComponent)

  Component {
    id: panelComponent

    DisplayPanel {
      theme: root.theme
      active: root.panelOpen
      outputName: root.barWindow.screen.name
    }
  }
}
