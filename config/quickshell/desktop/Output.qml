pragma ComponentBehavior: Bound

import QtQml
import Quickshell
import "../bar"
import "../modules/applications"
import "../modules/calculator"
import "../modules/menu"
import "../modules/notifications"
import "../modules/osd"
import "../modules/polkit"
import "../modules/wallpaper"

Scope {
  id: root

  required property var output
  required property var shellConfig
  required property var theme
  required property var systemState
  required property var osdState
  required property var notificationState
  required property var userRoot
  required property bool screenshotActive

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

    BarWindow {
      screen: root.output
      shellConfig: root.shellConfig
      theme: root.theme
      systemState: root.systemState
      screenshotActive: root.screenshotActive
    }
  }

  LazyLoader {
    active: root.shellConfig.menuEnabled

    MenuWindow {
      output: root.output
      theme: root.theme
    }
  }

  LazyLoader {
    active: root.shellConfig.applicationsEnabled

    ApplicationPickerWindow {
      output: root.output
      theme: root.theme
    }
  }

  LazyLoader {
    active: root.shellConfig.calculatorEnabled

    CalculatorWindow {
      output: root.output
      theme: root.theme
    }
  }

  LazyLoader {
    active: root.shellConfig.wallpaperEnabled

    WallpaperPickerWindow {
      output: root.output
      theme: root.theme
    }
  }

  LazyLoader {
    active: root.shellConfig.notificationsEnabled

    NotificationWindow {
      output: root.output
      notificationState: root.notificationState
      position: root.notificationPosition
      shellConfig: root.shellConfig
      theme: root.theme
    }
  }

  LazyLoader {
    active: root.shellConfig.osdEnabled

    OsdWindow {
      output: root.output
      osdState: root.osdState
      shellConfig: root.shellConfig
      theme: root.theme
    }
  }

  LazyLoader {
    active: root.shellConfig.polkitEnabled

    PolkitWindow {
      output: root.output
      theme: root.theme
    }
  }
}
