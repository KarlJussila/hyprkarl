pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import "../../config"
import "../../ui/modal"

QtObject {
  id: root

  readonly property string surface: "calculator"
  readonly property bool active: OverlayState.activeSurface === surface
  property var history: []

  property IpcHandler ipc: IpcHandler {
    target: "calculator"

    function open(output: string): bool {
      return OverlayState.replace(root.surface, output || OverlayState.focusedScreenName(), {})
    }

    function toggle(output: string): bool {
      return OverlayState.toggle(root.surface, output || OverlayState.focusedScreenName(), {})
    }

    function close(): void {
      OverlayState.close(root.surface)
    }
  }

  property FileView historyFile: FileView {
    path: Paths.stateHome + "/calculator-history.json"
    blockLoading: true
    printErrors: false
    onLoaded: root.history = JSON.parse(text())
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
