pragma ComponentBehavior: Bound

import QtQuick
import "../commands"
import "../../ui/controls"

ShellButton {
  id: root

  required property string widgetId
  required property var config
  required property var systemState

  readonly property bool hasProvider: config.command !== undefined
  readonly property var result: hasProvider
    ? CommandState.resultFor(widgetId)
    : ({
      "ready": true,
      "visible": true,
      "text": config.text ?? "",
      "icon": config.icon ?? "",
      "tooltip": config.tooltip ?? "",
      "state": config.state ?? "normal"
    })
  readonly property string icon: result.icon
  readonly property string value: result.text

  visible: result.ready && result.visible
    && (icon.length > 0 || value.length > 0)
  tooltip: result.tooltip
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
        color: root.semanticColor(root.result.state)
        font.family: root.theme.typography.uiFamily
        font.pixelSize: root.theme.typography.bodySize
        font.weight: root.theme.typography.weight
        font.styleName: root.theme.typography.style
      }

      Text {
        visible: root.value.length > 0
        text: root.value
        color: root.semanticColor(root.result.state)
        font.family: root.theme.typography.uiFamily
        font.pixelSize: root.theme.typography.bodySize
        font.weight: root.theme.typography.weight
        font.styleName: root.theme.typography.style
      }
    }
  }
}
