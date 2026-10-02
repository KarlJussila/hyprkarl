pragma ComponentBehavior: Bound

import QtQml
import Quickshell
import Quickshell.Io
import "../bar"
import "../config"
import "../ui/modal"
import "../modules/display"
import "../modules/notifications"
import "../modules/osd"

Scope {
  id: root

  property bool screenshotActive: false

  IpcHandler {
    target: "screenshot"

    function begin(): bool {
      root.screenshotActive = true
      return true
    }

    function finish(): bool {
      root.screenshotActive = false
      return true
    }
  }

  ShellConfig { id: configObject }
  Theme { id: themeObject }
  UserRoot {
    id: userRootObject
    shellConfig: configObject
    theme: themeObject
    overlayState: OverlayState
  }
  LazyLoader {
    active: configObject.modules.panels && themeObject.ready

    DisplayArrangement { shellContext: userRootObject.context }
  }
  LazyLoader {
    active: configObject.modules.panels && themeObject.ready

    DisplayConfirmation { shellContext: userRootObject.context }
  }
  LazyLoader {
    id: barStateLoader
    active: configObject.modules.bar

    BarState { shellConfig: configObject }
  }

  LazyLoader {
    id: osdStateLoader
    active: configObject.modules.osd

    OsdState { shellConfig: configObject }
  }

  LazyLoader {
    id: notificationStateLoader
    active: configObject.modules.notifications

    NotificationState { shellConfig: configObject }
  }

  Variants {
    model: themeObject.ready
      ? Quickshell.screens
      : []

    Output {
      required property var modelData

      output: modelData
      shellConfig: configObject
      theme: themeObject
      systemState: barStateLoader.item
      osdState: osdStateLoader.item
      notificationState: notificationStateLoader.item
      userRoot: userRootObject
      screenshotActive: root.screenshotActive
    }
  }
}
