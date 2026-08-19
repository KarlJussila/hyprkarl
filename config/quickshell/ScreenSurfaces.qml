pragma ComponentBehavior: Bound

import QtQml
import Quickshell
import "features/menu"
import "features/notifications"
import "features/osd"

Scope {
  id: root

  required property var output
  required property var shellConfig
  required property var theme
  required property var systemState
  required property var osdState
  required property var notificationState

  property Bar bar: Bar {
    screen: root.output
    shellConfig: root.shellConfig
    theme: root.theme
    systemState: root.systemState
  }

  property MenuWindow menu: MenuWindow {
    output: root.output
    theme: root.theme
  }

  property NotificationWindow notifications: NotificationWindow {
    output: root.output
    barWindow: root.bar
    notificationState: root.notificationState
    shellConfig: root.shellConfig
    theme: root.theme
  }

  property OsdWindow osd: OsdWindow {
    output: root.output
    osdState: root.osdState
    shellConfig: root.shellConfig
    theme: root.theme
  }
}
