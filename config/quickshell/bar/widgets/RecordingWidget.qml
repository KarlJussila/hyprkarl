import "../../ui/controls"

ShellButton {
  required property string widgetId
  required property var config
  required property var systemState

  visible: systemState.recording
  text: config.icon
  textColor: theme.palette.urgent
  tooltip: "Recording — click to stop"
  primaryCommand: config.command
}
