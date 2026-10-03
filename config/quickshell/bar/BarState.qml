import QtQml
import "commands"

SystemMonitor {
  id: root

  required property var shellConfig

  readonly property var commandProviders: {
    const layout = shellConfig.bar.layout
    const anchor = layout.center.anchor ? [layout.center.anchor] : []
    return layout.start.concat(layout.center.before, anchor, layout.center.after, layout.end)
      .filter(widget => widget.kind === "command" && widget.command !== undefined)
  }
  onCommandProvidersChanged: CommandState.configure(commandProviders)
  Component.onCompleted: CommandState.configure(commandProviders)
}
