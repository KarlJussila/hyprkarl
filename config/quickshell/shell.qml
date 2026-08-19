//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import Quickshell
import "config"
import "features/menu"
import "features/notifications"
import "features/osd"
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
