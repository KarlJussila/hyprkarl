//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import QtQml
import Quickshell
import "config"
import "features/menu"
import "features/notifications"
import "features/osd"
import "features/overlay"
import "state"

ShellRoot {
  ShellConfig { id: configObject }
  Theme { id: themeObject }
  UserRoot {
    id: userRootObject
    shellConfig: configObject
    theme: themeObject
    overlayState: OverlayState
  }
  LazyLoader {
    id: barRuntimeLoader
    active: configObject.barEnabled

    BarRuntime { shellConfig: configObject }
  }

  LazyLoader {
    id: osdStateLoader
    active: configObject.osdEnabled

    OsdState { shellConfig: configObject }
  }

  LazyLoader {
    id: notificationStateLoader
    active: configObject.notificationsEnabled

    NotificationState { shellConfig: configObject }
  }

  Variants {
    model: configObject.ready
      && themeObject.ready
      && (!configObject.menuEnabled || MenuState.ready)
      ? Quickshell.screens
      : []

    ScreenSurfaces {
      required property var modelData

      output: modelData
      shellConfig: configObject
      theme: themeObject
      systemState: barRuntimeLoader.item
      osdState: osdStateLoader.item
      notificationState: notificationStateLoader.item
      userRoot: userRootObject
    }
  }
}
