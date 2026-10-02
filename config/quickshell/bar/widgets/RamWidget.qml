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

  function gib(value: real): string {
    return `${(value / 1073741824).toFixed(1)}G`
  }

  function render(template: string): string {
    return template.replace("{usedPercent}", Math.round(systemState.ramUsedPercent))
      .replace("{used}", gib(systemState.ramUsed))
      .replace("{total}", gib(systemState.ramTotal))
      .replace("{swapUsed}", gib(systemState.swapUsed))
      .replace("{swapTotal}", gib(systemState.swapTotal))
  }

  contentComponent: Component {
    ExpandableReadout {
      icon: root.config.icon
      text: root.render(root.alternate ? root.config.alternate : root.config.primary)
      expanded: root.expanded
      theme: root.theme
    }
  }
  tooltip: `RAM: ${Math.round(systemState.ramUsedPercent)}% · ${gib(systemState.ramUsed)}/${gib(systemState.ramTotal)} · Swap ${gib(systemState.swapUsed)}/${gib(systemState.swapTotal)}`
  onPrimary: () => expanded = !expanded
  onSecondary: () => alternate = !alternate
}
