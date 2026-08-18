import "../components"

ShellButton {
  required property string widgetId
  required property var config
  required property var systemState

  text: config.icon
  primaryCommand: config.command
}
