pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

import "MenuModel.js" as MenuModel
import "../../config"
import "../../ui/modal"

QtObject {
  id: root

  readonly property string surface: "menu"
  readonly property bool requested: OverlayState.activeSurface === surface
  readonly property string screenName: requested ? OverlayState.screenName : ""
  property string currentMenu: ""
  property var history: []
  property var views: ({})
  property int openRevision: 0
  property string dynamicMenuId: ""
  property var dynamicEntries: []
  property string dynamicError: ""
  property bool sourceLoading: false
  property bool sourceCancelled: false
  property string sourceMenuId: ""
  property string sourceScreenName: ""
  property var sourceHistory: []

  property JsonSettings config: JsonSettings {
    defaultPath: Paths.defaultsRoot + "/menu.json"
    personalPath: Paths.userPath("settings/menu.json")
  }
  readonly property var menus: config.values.menus
  readonly property var entries: config.values.entries

  property IpcHandler ipc: IpcHandler {
    target: "menu"

    function open(output: string, menu: string): bool {
      return root.openForScreen(output || OverlayState.focusedScreenName(), menu)
    }

    function toggle(output: string, menu: string): bool {
      return root.toggleForScreen(output || OverlayState.focusedScreenName(), menu)
    }

    function close(): void {
      root.close()
    }
  }

  property Process dynamicSource: Process {
    stdout: StdioCollector {
      onStreamFinished: root.finishDynamicSource(text)
    }
  }

  property Connections overlayConnection: Connections {
    target: OverlayState

    function onActiveSurfaceChanged(): void {
      if (OverlayState.activeSurface === root.surface || !root.sourceLoading) return
      root.sourceCancelled = true
      root.dynamicSource.running = false
      root.sourceLoading = false
    }
  }

  function entriesFor(menuId: string, query: string): var {
    return MenuModel.entriesFor(entries, menuId, dynamicMenuId,
      dynamicEntries, query)
  }

  function historyKey(): string {
    return JSON.stringify(history)
  }

  function rememberView(query: string, selectedEntry: string,
      contentY: real): void {
    if (history.length === 0) return
    const next = Object.assign({}, views)
    next[historyKey()] = {
      "query": query,
      "selectedEntry": selectedEntry,
      "contentY": contentY
    }
    views = next
  }

  function currentView(): var {
    return views[historyKey()] ?? null
  }

  function menuMessage(menuId: string, query: string): string {
    if (dynamicMenuId === menuId) {
      if (dynamicError.length > 0) return dynamicError
    }
    if (query.trim().length > 0) return "No matches"
    return menus[menuId]?.emptyLabel ?? "No entries"
  }

  function showMenu(screen: string, nextHistory, menuId: string,
      loadedEntries, error: string): void {
    history = nextHistory
    currentMenu = menuId
    dynamicMenuId = menus[menuId]?.sourceCommand === undefined ? "" : menuId
    dynamicEntries = loadedEntries
    dynamicError = error
    openRevision++
    OverlayState.replace(surface, screen, {})
  }

  function enterMenu(screen: string, nextHistory, menuId: string): bool {
    const sourceCommand = menus[menuId]?.sourceCommand
    if (typeof sourceCommand !== "string") {
      showMenu(screen, nextHistory, menuId, [], "")
      return true
    }

    if (sourceLoading) return false
    sourceLoading = true
    sourceCancelled = false
    sourceMenuId = menuId
    sourceScreenName = screen
    sourceHistory = nextHistory
    dynamicSource.command = ["bash", "-c", sourceCommand]
    dynamicSource.running = true
    return true
  }

  function finishDynamicSource(output: string): void {
    sourceLoading = false
    if (sourceCancelled) return

    // Dynamic entries are a JSON array from the menu's sourceCommand.
    let loadedEntries = []
    let errorMessage = ""
    try {
      loadedEntries = JSON.parse(output).map((entry, index) => Object.assign({
        "parent": sourceMenuId,
        "order": (index + 1) * 10
      }, entry))
    } catch (error) {
      errorMessage = "Could not load entries"
      console.error(`Menu '${sourceMenuId}' source: ${error}`)
    }
    showMenu(sourceScreenName, sourceHistory, sourceMenuId,
      loadedEntries, errorMessage)
  }

  function openForScreen(name: string, menu: string): bool {
    if (name.length === 0 || !menus[menu]) return false
    views = ({})
    return enterMenu(name, [menu], menu)
  }

  function toggleForScreen(name: string, menu: string): bool {
    if (sourceLoading && sourceScreenName === name && sourceMenuId === menu) {
      close()
      return true
    }
    if (requested && screenName === name && currentMenu === menu) {
      close()
      return true
    }
    return openForScreen(name, menu)
  }

  function close(): void {
    if (sourceLoading) {
      sourceCancelled = true
      dynamicSource.running = false
    }
    OverlayState.close(surface)
  }

  function back(): void {
    if (sourceLoading) return
    if (history.length <= 1) {
      close()
      return
    }
    const next = history.slice(0, -1)
    enterMenu(screenName, next, next[next.length - 1])
  }

  function activate(entry): void {
    if (sourceLoading) return
    if (entry.action.type === "menu") {
      enterMenu(screenName, history.concat([entry.action.menu]), entry.action.menu)
      return
    }
    if (entry.action.type === "surface") {
      OverlayState.push(entry.action.surface, screenName,
        entry.action.parameters ?? {})
      return
    }

    close()
    if (entry.action.type === "command") {
      Quickshell.execDetached(["uwsm-app", "--", "bash", "-c", entry.action.command])
    }
  }
}
