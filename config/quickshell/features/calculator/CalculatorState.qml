pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import "../overlay"

QtObject {
  id: root

  readonly property string surface: "calculator"
  readonly property bool active: OverlayState.activeSurface === surface
  readonly property string stateHome: (Quickshell.env("XDG_STATE_HOME")
    ?? Quickshell.env("HOME") + "/.local/state") + "/hyprkarl"
  property var history: []

  property IpcHandler ipc: IpcHandler {
    target: "calculator"

    function open(): bool {
      return OverlayState.replaceFocused(root.surface, {})
    }

    function openForScreen(screen: string): bool {
      return OverlayState.replace(root.surface, screen, {})
    }

    function toggle(): bool {
      return OverlayState.toggleFocused(root.surface)
    }

    function toggleForScreen(screen: string): bool {
      return OverlayState.toggle(root.surface, screen, {})
    }

    function close(): void {
      OverlayState.close(root.surface)
    }
  }

  property FileView historyFile: FileView {
    path: root.stateHome + "/calculator-history.json"
    blockLoading: true
    printErrors: false

    onLoaded: {
      try {
        root.history = JSON.parse(text())
      } catch (error) {
        console.error("Calculator history rejected: " + error)
      }
    }

    onLoadFailed: error => {
      if (error !== FileViewError.FileNotFound) {
        console.error("Could not read calculator history: "
          + FileViewError.toString(error))
      }
    }
  }

  function close(): void {
    OverlayState.close(surface)
  }

  function addHistory(expression: string, result: string): void {
    const next = history.filter(entry => entry.expression !== expression)
    next.unshift({ "expression": expression, "result": result })
    history = next.slice(0, 5)
    historyFile.setText(JSON.stringify(history))
  }
}
