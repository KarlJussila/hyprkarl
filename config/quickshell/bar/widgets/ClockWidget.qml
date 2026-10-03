pragma ComponentBehavior: Bound

import QtQuick
import "../../modules/clock"
import "../../ui/controls"

ShellButton {
  id: root

  required property string widgetId
  required property var config
  required property var systemState

  property bool alternate: false
  readonly property bool panelOpen: panelHost?.activeId === widgetId

  text: Qt.formatDateTime(ClockState.date, alternate ? config.alternateFormat : config.format)
  tooltip: Qt.formatDateTime(ClockState.date, "dddd, MMMM d, yyyy h:mm:ss AP")
  tooltipSuppressed: panelOpen
  onPrimary: panelHost
    ? () => panelHost.toggle(widgetId, root, panelComponent)
    : null
  onSecondary: () => alternate = !alternate

  Component {
    id: panelComponent

    ClockPanel {
      theme: root.theme
      active: root.panelOpen
    }
  }
}
