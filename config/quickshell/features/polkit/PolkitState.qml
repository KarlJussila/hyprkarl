pragma Singleton

import QtQml
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Polkit

QtObject {
  id: root

  property string screenName: ""
  readonly property var flow: agent.flow
  readonly property bool requested: agent.isActive

  function focusedScreenName(): string {
    return Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? ""
  }

  function screenExists(name): bool {
    return Quickshell.screens.some(screen => screen.name === name)
  }

  function resolvedScreenName(): string {
    if (screenExists(screenName)) return screenName
    return Quickshell.screens[0]?.name ?? ""
  }

  property PolkitAgent agent: PolkitAgent {

    onAuthenticationRequestStarted: {
      root.screenName = root.focusedScreenName()
      console.info(`Polkit authentication requested on ${root.screenName}`)
    }

    onIsRegisteredChanged:
      console.info(`Polkit agent registered: ${isRegistered}`)
  }
}
