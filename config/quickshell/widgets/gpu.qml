pragma ComponentBehavior: Bound

import QtQuick
import "../components"

ShellButton {
  id: root

  required property string widgetId
  required property var config
  required property var systemState

  property bool alternate: false
  property bool expanded: false

  function gib(value: real): string {
    return `${(value / 1073741824).toFixed(1)}G`
  }

  function render(template: string): string {
    return template.replace("{usage}", Math.round(systemState.gpuUsage))
      .replace("{vramUsed}", gib(systemState.gpuVramUsed))
      .replace("{vramTotal}", gib(systemState.gpuVramTotal))
  }

  contentComponent: Component {
    ExpandableReadout {
      icon: "󰢮"
      text: root.render(root.alternate ? root.config.alternate : root.config.primary)
      expanded: root.expanded
      theme: root.theme
    }
  }
  onPrimary: () => expanded = !expanded
  onSecondary: () => alternate = !alternate
}
