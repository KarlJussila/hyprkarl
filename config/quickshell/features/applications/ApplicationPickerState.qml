pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import "../overlay"

QtObject {
  id: root

  readonly property string launcherSurface: "launcher"
  readonly property string openWithSurface: "open-with"
  readonly property bool launcherActive: OverlayState.activeSurface === launcherSurface
  readonly property bool openWithActive: OverlayState.activeSurface === openWithSurface
  readonly property bool active: launcherActive || openWithActive

  property string filePath: ""
  property string mimeType: ""
  property var openWithEntries: []
  property bool openWithLoading: false
  property string openWithError: ""
  property bool setDefault: false
  readonly property var launcherEntries: DesktopEntries.applications.values
    .map(application => ({
      "id": application.id,
      "name": application.name,
      "genericName": application.genericName,
      "icon": application.icon,
      "searchText": [
        application.name,
        application.genericName,
        application.comment,
        application.id,
        application.command.join(" "),
        application.categories.join(" "),
        application.keywords.join(" ")
      ].join(" ")
    }))
    .sort((left, right) => left.name.localeCompare(right.name))

  signal requested()

  property Connections overlayConnection: Connections {
    target: OverlayState

    function onOpenRevisionChanged(): void {
      if (OverlayState.activeSurface === root.launcherSurface) {
        root.requested()
      } else if (OverlayState.activeSurface === root.openWithSurface) {
        root.loadFile(OverlayState.parameters.path ?? "")
        root.requested()
      }
    }
  }

  property IpcHandler launcherIpc: IpcHandler {
    target: "launcher"

    function open(): bool {
      return root.openLauncher(OverlayState.focusedScreenName())
    }

    function openForScreen(screen: string): bool {
      return root.openLauncher(screen)
    }

    function toggle(): bool {
      return root.toggleLauncher(OverlayState.focusedScreenName())
    }

    function toggleForScreen(screen: string): bool {
      return root.toggleLauncher(screen)
    }

    function close(): void {
      OverlayState.close(root.launcherSurface)
    }
  }

  property IpcHandler openWithIpc: IpcHandler {
    target: "openWith"

    function open(path: string): bool {
      return root.openFile(OverlayState.focusedScreenName(), path)
    }

    function openForScreen(screen: string, path: string): bool {
      return root.openFile(screen, path)
    }

    function close(): void {
      OverlayState.close(root.openWithSurface)
    }
  }

  property Process openWithSource: Process {
    stdout: StdioCollector { id: sourceOutput }
    stderr: StdioCollector { id: sourceError }

    // qmllint disable signal-handler-parameters
    onExited: exitCode => {
      root.openWithLoading = false
      if (!root.openWithActive) return
      if (exitCode !== 0) {
        root.openWithError = sourceError.text.trim() || "Could not load applications"
        root.openWithEntries = []
        return
      }

      try {
        const data = JSON.parse(sourceOutput.text)
        root.mimeType = data.mimeType
        root.openWithEntries = data.entries
        root.openWithError = ""
      } catch (error) {
        root.openWithEntries = []
        root.openWithError = "Could not load applications"
        console.error("Open-with entries rejected: " + error)
      }
    }
    // qmllint enable signal-handler-parameters
  }

  function openLauncher(screen: string): bool {
    return OverlayState.open(launcherSurface, screen, {})
  }

  function toggleLauncher(screen: string): bool {
    return OverlayState.toggle(launcherSurface, screen)
  }

  function openFile(screen: string, path: string): bool {
    if (screen.length === 0 || path.length === 0) return false
    return OverlayState.open(openWithSurface, screen, { "path": path })
  }

  function loadFile(path: string): void {
    filePath = path
    mimeType = ""
    openWithEntries = []
    openWithError = ""
    openWithLoading = true
    setDefault = false
    openWithSource.exec(["hk-open-with", "entries", path])
  }

  function close(): void {
    if (active) OverlayState.close(OverlayState.activeSurface)
  }

  function matches(entry, terms): bool {
    const searchText = entry.searchText.toLowerCase()
    return terms.every(term => searchText.includes(term))
  }

  function entriesFor(query: string): var {
    const entries = openWithActive ? openWithEntries : launcherEntries
    const terms = query.trim().toLowerCase().split(/\s+/)
      .filter(term => term.length > 0)
    return terms.length === 0
      ? entries
      : entries.filter(entry => matches(entry, terms))
  }

  function activate(entry): void {
    const surface = OverlayState.activeSurface
    const path = filePath
    const makeDefault = setDefault
    OverlayState.close(surface)

    if (surface === launcherSurface) {
      Quickshell.execDetached(["gtk-launch", entry.id])
      return
    }

    Quickshell.execDetached([
      "hk-open-with", "launch", path, entry.id,
      makeDefault ? "true" : "false"
    ])
  }
}
