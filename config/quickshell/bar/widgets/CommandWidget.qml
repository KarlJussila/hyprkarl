pragma ComponentBehavior: Bound

import QtQuick
import "../commands"
import "../../ui/controls"

ShellButton {
  id: root

  required property string widgetId
  required property var config
  required property var systemState

  // The command's latest output overrides the widget's own values; a widget
  // with a command stays hidden until its first output.
  readonly property var output: config.command === undefined
    ? ({})
    : CommandState.results[widgetId]
  readonly property string icon: output?.icon ?? config.icon ?? ""
  readonly property string value: output?.text ?? config.text ?? ""
  readonly property string semanticState: output?.state ?? config.state ?? "normal"

  visible: !!output && (output.visible ?? true)
    && (icon.length > 0 || value.length > 0)
  tooltip: output?.tooltip ?? config.tooltip ?? ""
  onPrimary: config.primaryCommand
    ? () => root.launchPanelCommand(config.primaryCommand)
    : null
  onSecondary: config.secondaryCommand
    ? () => root.launchPanelCommand(config.secondaryCommand)
    : null
  onTertiary: config.tertiaryCommand
    ? () => root.launchPanelCommand(config.tertiaryCommand)
    : null

  function semanticColor(state): color {
    if (state === "muted") return theme.palette.muted
    if (state === "accent") return theme.palette.accent
    if (state === "warning") return theme.palette.warning
    if (state === "urgent") return theme.palette.urgent
    return theme.palette.foreground
  }

  contentComponent: Component {
    Row {
      spacing: root.icon.length > 0 && root.value.length > 0 ? 4 : 0

      Text {
        visible: root.icon.length > 0
        text: root.icon
        color: root.semanticColor(root.semanticState)
        font.family: root.theme.typography.uiFamily
        font.pixelSize: root.theme.typography.bodySize
        font.weight: root.theme.typography.weight
        font.styleName: root.theme.typography.style
      }

      Text {
        visible: root.value.length > 0
        text: root.value
        color: root.semanticColor(root.semanticState)
        font.family: root.theme.typography.uiFamily
        font.pixelSize: root.theme.typography.bodySize
        font.weight: root.theme.typography.weight
        font.styleName: root.theme.typography.style
      }
    }
  }
}
