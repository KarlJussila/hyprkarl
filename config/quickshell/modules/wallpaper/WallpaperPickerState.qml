pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import "../../ui/modal"
import "../../config"

QtObject {
  id: root

  readonly property string surface: "wallpaper"
  readonly property bool active: OverlayState.activeSurface === surface
  property string action: "set"
  property var entries: []
  property bool loading: false
  property string error: ""

  property Connections overlayConnection: Connections {
    target: OverlayState

    function onOpenRevisionChanged(): void {
      if (OverlayState.activeSurface !== root.surface) return
      root.load(OverlayState.parameters.action ?? "set")
    }
  }

  property IpcHandler ipc: IpcHandler {
    target: "wallpaper"

    function open(output: string, action: string): bool {
      return root.openForScreen(output || Screens.focusedName(), action)
    }

    function close(): void {
      root.close()
    }
  }

  property Process source: Process {
    stdout: StdioCollector { id: sourceOutput }
    stderr: StdioCollector { id: sourceError }

    // qmllint disable signal-handler-parameters
    onExited: exitCode => {
      root.loading = false
      if (!root.active) return
      if (exitCode !== 0) {
        root.entries = []
        root.error = sourceError.text.trim() || "Could not load wallpapers"
        return
      }

      try {
        root.entries = JSON.parse(sourceOutput.text)
        root.error = ""
      } catch (error) {
        root.entries = []
        root.error = "Could not load wallpapers"
        console.error("Wallpaper entries rejected: " + error)
      }
    }
    // qmllint enable signal-handler-parameters
  }

  function openForScreen(screen: string, nextAction: string): bool {
    if (screen.length === 0 || !["set", "remove"].includes(nextAction)) return false
    return OverlayState.replace(surface, screen, { "action": nextAction })
  }

  function load(nextAction: string): void {
    action = nextAction
    entries = []
    error = ""
    loading = true
    source.exec(["hk-wallpaper-entries"])
  }

  function close(): void {
    OverlayState.close(surface)
  }

  function activate(entry): void {
    const command = action
    close()
    Quickshell.execDetached(["uwsm-app", "--", "hk-wallpaper", command, entry.name])
  }
}
