pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import "../features/clock"

ShellButton {
  id: root

  required property string widgetId
  required property var config
  required property var systemState

  property bool alternate: false
  readonly property bool panelOpen: panelHost.activeId === widgetId

  text: Qt.formatDateTime(ClockState.now, alternate ? config.alternate : config.primary)
  tooltip: Qt.formatDateTime(ClockState.now, "dddd, MMMM d, yyyy h:mm:ss AP")
  tooltipSuppressed: panelOpen
  onPrimary: () => panelHost.toggle(widgetId, root, panelComponent)
  onSecondary: () => alternate = !alternate

  Component {
    id: panelComponent

    ClockPanel {
      theme: root.theme
      active: root.panelOpen
    }
  }
}
