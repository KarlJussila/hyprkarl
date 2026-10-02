pragma ComponentBehavior: Bound

import QtQuick
import "../../ui/controls"

ShellButton {
  id: root

  required property string widgetId
  required property var config
  required property var systemState

  property bool alternate: false
  property bool expanded: false

  function render(template: string): string {
    return template.replace("{temp}", Math.round(systemState.cpuTemp))
      .replace("{usage}", Math.round(systemState.cpuUsage))
  }

  contentComponent: Component {
    ExpandableReadout {
      icon: "󰍛"
      text: root.render(root.alternate ? root.config.alternateFormat : root.config.format)
      expanded: root.expanded
      theme: root.theme
    }
  }
  tooltip: `CPU: ${Math.round(systemState.cpuUsage)}%`
  onPrimary: () => expanded = !expanded
  onSecondary: () => alternate = !alternate
}
