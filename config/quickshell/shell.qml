//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import QtQml
import Quickshell
import "config"
import "features/command"
import "features/menu"
import "features/notifications"
import "features/osd"
import "features/polkit"
import "state"

ShellRoot {
  ShellConfig { id: configObject }
  Theme { id: themeObject }
  SystemState { id: stateObject }
  OsdState {
    id: osdStateObject
    shellConfig: configObject
  }
  NotificationState {
    id: notificationStateObject
    shellConfig: configObject
  }

  property var polkitState: PolkitState

  Connections {
    target: configObject

    function onCommandProvidersChanged(): void {
      CommandState.configure(configObject.commandProviders)
    }
  }

  Component.onCompleted: CommandState.configure(configObject.commandProviders)

  Variants {
    model: configObject.ready && themeObject.ready && MenuState.ready
      ? Quickshell.screens
      : []

    ScreenSurfaces {
      required property var modelData

      output: modelData
      shellConfig: configObject
      theme: themeObject
      systemState: stateObject
      osdState: osdStateObject
      notificationState: notificationStateObject
    }
  }
}
