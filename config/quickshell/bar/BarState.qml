import QtQml
import "commands"

SystemMonitor {
  id: root

  required property var shellConfig
  active: true

  property Connections providerConnections: Connections {
    target: root.shellConfig

    function onCommandProvidersChanged(): void {
      CommandState.configure(root.shellConfig.commandProviders)
    }
  }

  Component.onCompleted:
    CommandState.configure(shellConfig.commandProviders)
}
