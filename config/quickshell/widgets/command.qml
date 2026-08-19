pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import "../features/command"

ShellButton {
  id: root

  required property string widgetId
  required property var config
  required property var systemState

  readonly property var result: CommandState.resultFor(widgetId)
  readonly property string icon: result.icon
  readonly property string value: result.text

  visible: result.ready && result.visible
    && (icon.length > 0 || value.length > 0)
  tooltip: result.tooltip
  primaryCommand: config.primaryCommand ?? ""
  secondaryCommand: config.secondaryCommand ?? ""
  tertiaryCommand: config.tertiaryCommand ?? ""

  function semanticColor(state): color {
    if (state === "muted") return theme.muted
    if (state === "accent") return theme.accent
    if (state === "warning") return theme.warning
    if (state === "urgent") return theme.urgent
    return theme.foreground
  }

  contentComponent: Component {
    Row {
      spacing: root.icon.length > 0 && root.value.length > 0 ? 4 : 0

      Text {
        visible: root.icon.length > 0
        text: root.icon
        color: root.semanticColor(root.result.state)
        font.family: root.theme.uiFontFamily
        font.pixelSize: root.theme.bodyFontSize
        font.weight: root.theme.fontWeight
        font.styleName: root.theme.fontStyle
      }

      Text {
        visible: root.value.length > 0
        text: root.value
        color: root.semanticColor(root.result.state)
        font.family: root.theme.uiFontFamily
        font.pixelSize: root.theme.bodyFontSize
        font.weight: root.theme.fontWeight
        font.styleName: root.theme.fontStyle
      }
    }
  }
}
