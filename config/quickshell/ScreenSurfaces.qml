pragma ComponentBehavior: Bound

import QtQml
import Quickshell
import "features/applications"
import "features/calculator"
import "features/menu"
import "features/notifications"
import "features/osd"
import "features/polkit"
import "features/wallpaper"

Scope {
  id: root

  required property var output
  required property var shellConfig
  required property var theme
  required property var systemState
  required property var osdState
  required property var notificationState
  required property var userRoot

  readonly property var barWindow: barLoader.item
  readonly property var notificationPosition: resolveNotificationPosition()

  function builtInNotificationPosition(): var {
    const bar = root.barWindow
    const visible = bar !== null && bar.visibleExtent > 0
    return {
      "edge": root.shellConfig.edge,
      "extent": visible ? bar.visibleExtent : 0,
      "connected": visible && root.theme.barMarginContent === 0,
      "reachesSide": visible && root.theme.barMarginOuter === 0
    }
  }

  function resolveNotificationPosition(): var {
    if (root.shellConfig.notificationEdge !== "bar") {
      return {
        "edge": root.shellConfig.notificationEdge,
        "extent": 0,
        "connected": false,
        "reachesSide": false
      }
    }

    const fallback = builtInNotificationPosition()
    const custom = root.userRoot.notificationPosition(root.output.name)
    return custom === null || custom === undefined
      ? fallback
      : Object.assign({}, fallback, custom)
  }

  LazyLoader {
    id: barLoader
    active: root.shellConfig.barEnabled

    Bar {
      screen: root.output
      shellConfig: root.shellConfig
      theme: root.theme
      systemState: root.systemState
    }
  }

  property MenuWindow menu: MenuWindow {
    output: root.output
    theme: root.theme
  }

  property ApplicationPickerWindow applications: ApplicationPickerWindow {
    output: root.output
    theme: root.theme
  }

  property CalculatorWindow calculator: CalculatorWindow {
    output: root.output
    theme: root.theme
  }

  property WallpaperPickerWindow wallpaperPicker: WallpaperPickerWindow {
    output: root.output
    theme: root.theme
  }

  property NotificationWindow notifications: NotificationWindow {
    output: root.output
    notificationState: root.notificationState
    position: root.notificationPosition
    shellConfig: root.shellConfig
    theme: root.theme
  }

  property OsdWindow osd: OsdWindow {
    output: root.output
    osdState: root.osdState
    shellConfig: root.shellConfig
    theme: root.theme
  }

  property PolkitWindow polkit: PolkitWindow {
    output: root.output
    theme: root.theme
  }
}
