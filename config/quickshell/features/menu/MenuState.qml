pragma Singleton

import QtQml
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

QtObject {
  id: root

  readonly property url defaultPath: Quickshell.shellPath("../../defaults/menu.json")
  readonly property url userPath: Quickshell.shellPath("../../user/menu.json")

  property var values: ({})
  property bool ready: false
  property bool requested: false
  property string screenName: ""
  property string currentMenu: ""
  property var history: []
  property int openRevision: 0
  property string dynamicMenuId: ""
  property var dynamicEntries: []
  property string dynamicError: ""
  property bool sourceLoading: false
  property bool sourceCancelled: false
  property string sourceMenuId: ""
  property string sourceScreenName: ""
  property var sourceHistory: []
  property string lastError: ""
  property bool loading: false
  property bool defaultResolved: false
  property bool userResolved: false
  property string defaultReadError: ""
  property string userReadError: ""
  property bool userMissing: true

  readonly property string rootMenu: values.root ?? "main"
  readonly property var menus: values.menus ?? ({})
  readonly property var entries: values.entries ?? ({})

  property FileView defaultSource: FileView {
    path: root.defaultPath
    blockLoading: true
    watchChanges: true

    onFileChanged: {
      root.defaultResolved = false
      reload()
    }
    onLoaded: {
      root.defaultResolved = true
      root.defaultReadError = ""
      root.loadSelected()
    }
    onLoadFailed: error => {
      root.defaultResolved = true
      root.defaultReadError = FileViewError.toString(error)
      root.loadSelected()
    }
  }

  property FileView userSource: FileView {
    path: root.userPath
    blockLoading: true
    watchChanges: true
    printErrors: false

    onFileChanged: {
      root.userResolved = false
      reload()
    }
    onLoaded: {
      root.userResolved = true
      root.userReadError = ""
      root.userMissing = false
      root.loadSelected()
    }
    onLoadFailed: error => {
      root.userResolved = true
      root.userReadError = FileViewError.toString(error)
      root.userMissing = error === FileViewError.FileNotFound
      root.loadSelected()
    }
  }

  property IpcHandler ipc: IpcHandler {
    target: "menu"

    function toggle(menu: string): bool {
      return root.toggleOnFocusedScreen(menu)
    }

    function open(menu: string): bool {
      return root.openOnFocusedScreen(menu)
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

  function fail(path, message): void {
    throw new Error(path + ": " + message)
  }

  function isObject(value): bool {
    return value !== null && typeof value === "object" && !Array.isArray(value)
  }

  function requireObject(value, path): void {
    if (!isObject(value)) fail(path, "expected an object")
  }

  function clone(value): var {
    if (Array.isArray(value)) return value.map(entry => clone(entry))
    if (!isObject(value)) return value

    const copy = {}
    for (const key of Object.keys(value)) copy[key] = clone(value[key])
    return copy
  }

  function merge(base, override): var {
    if (!isObject(base) || !isObject(override)) return clone(override)

    const result = clone(base)
    for (const key of Object.keys(override)) {
      result[key] = key in result ? merge(result[key], override[key]) : clone(override[key])
    }
    return result
  }

  function parse(text, path): var {
    try {
      return JSON.parse(text)
    } catch (error) {
      fail(path, "invalid JSON (" + error + ")")
    }
  }

  function validate(document, path, sparse): void {
    requireObject(document, path)
    if (document.version !== 1) {
      fail(path + ".version", "unsupported menu configuration version '" + document.version + "'")
    }

    if (sparse) {
      if (document.root !== undefined && typeof document.root !== "string") {
        fail(path + ".root", "expected a menu id")
      }
      if (document.menus !== undefined) requireObject(document.menus, path + ".menus")
      if (document.entries !== undefined) requireObject(document.entries, path + ".entries")
      return
    }

    if (typeof document.root !== "string" || document.root.length === 0) {
      fail(path + ".root", "expected a menu id")
    }
    requireObject(document.menus, path + ".menus")
    requireObject(document.entries, path + ".entries")

    for (const menuId of Object.keys(document.menus)) {
      const menuPath = path + ".menus." + menuId
      const menu = document.menus[menuId]
      requireObject(menu, menuPath)
      if (typeof menu.title !== "string" || menu.title.length === 0) {
        fail(menuPath + ".title", "expected a non-empty string")
      }
      if (menu.sourceCommand !== undefined
          && (typeof menu.sourceCommand !== "string" || menu.sourceCommand.length === 0)) {
        fail(menuPath + ".sourceCommand", "expected a non-empty command")
      }
      if (menu.emptyLabel !== undefined
          && (typeof menu.emptyLabel !== "string" || menu.emptyLabel.length === 0)) {
        fail(menuPath + ".emptyLabel", "expected a non-empty string")
      }
      if (menu.searchable !== undefined && typeof menu.searchable !== "boolean") {
        fail(menuPath + ".searchable", "expected a boolean")
      }
      if (menu.widthRole !== undefined
          && !["default", "search", "reference"].includes(menu.widthRole)) {
        fail(menuPath + ".widthRole", "expected 'default', 'search', or 'reference'")
      }
    }
    if (!document.menus[document.root]) {
      fail(path + ".root", "unknown menu '" + document.root + "'")
    }

    for (const entryId of Object.keys(document.entries)) {
      const entryPath = path + ".entries." + entryId
      const entry = document.entries[entryId]
      requireObject(entry, entryPath)
      if (typeof entry.parent !== "string" || !document.menus[entry.parent]) {
        fail(entryPath + ".parent", "unknown parent menu '" + entry.parent + "'")
      }
      if (typeof entry.order !== "number" || !Number.isFinite(entry.order)) {
        fail(entryPath + ".order", "expected a number")
      }
      if (typeof entry.label !== "string" || entry.label.length === 0) {
        fail(entryPath + ".label", "expected a non-empty string")
      }
      if (entry.icon !== undefined && typeof entry.icon !== "string") {
        fail(entryPath + ".icon", "expected a string")
      }
      if (entry.enabled !== undefined && typeof entry.enabled !== "boolean") {
        fail(entryPath + ".enabled", "expected a boolean")
      }
      if (entry.checkedCommand !== undefined
          && (typeof entry.checkedCommand !== "string" || entry.checkedCommand.length === 0)) {
        fail(entryPath + ".checkedCommand", "expected a non-empty command")
      }

      requireObject(entry.action, entryPath + ".action")
      if (entry.action.type === "command") {
        if (typeof entry.action.command !== "string" || entry.action.command.length === 0) {
          fail(entryPath + ".action.command", "expected a non-empty command")
        }
      } else if (entry.action.type === "menu") {
        if (typeof entry.action.menu !== "string" || !document.menus[entry.action.menu]) {
          fail(entryPath + ".action.menu", "unknown menu '" + entry.action.menu + "'")
        }
      } else if (entry.action.type === "dismiss") {
        // Informational entries close the menu when activated.
      } else {
        fail(entryPath + ".action.type", "expected 'command', 'menu', or 'dismiss'")
      }
    }
  }

  function apply(document): void {
    values = document
    ready = true
    lastError = ""
    if (requested && !menus[currentMenu]) close()
    if (sourceLoading && !menus[sourceMenuId]) close()
  }

  function loadSelected(): void {
    if (!defaultResolved || !userResolved || loading) return
    loading = true

    try {
      if (defaultReadError.length > 0 || !defaultSource.loaded) {
        fail(defaultPath, "could not read shipped default (" + defaultReadError + ")")
      }
      const defaults = parse(defaultSource.text(), defaultPath)
      validate(defaults, defaultPath, false)

      if (userMissing) {
        apply(defaults)
      } else {
        try {
          if (userReadError.length > 0 || !userSource.loaded) {
            fail(userPath, "could not read user configuration (" + userReadError + ")")
          }
          const override = parse(userSource.text(), userPath)
          validate(override, userPath, true)
          const effective = merge(defaults, override)
          validate(effective, userPath + " (effective)", false)
          apply(effective)
        } catch (error) {
          const message = String(error)
          console.error("Menu configuration rejected: " + message)
          if (!ready) apply(defaults)
          lastError = message
        }
      }
    } catch (error) {
      lastError = String(error)
      console.error("Menu configuration failed: " + lastError)
      if (!ready) throw error
    } finally {
      loading = false
    }
  }

  function fuzzyMatch(text: string, pattern: string): bool {
    let patternIndex = 0
    for (let textIndex = 0; textIndex < text.length && patternIndex < pattern.length; textIndex++) {
      if (text[textIndex] === pattern[patternIndex]) patternIndex++
    }
    return patternIndex === pattern.length
  }

  function entriesFor(menuId: string, query: string): var {
    const result = []
    for (const entryId of Object.keys(entries)) {
      const entry = entries[entryId]
      if (entry.parent === menuId && entry.enabled !== false) {
        result.push(Object.assign({ "id": entryId }, entry))
      }
    }
    result.sort((left, right) => left.order === right.order
      ? left.id.localeCompare(right.id)
      : left.order - right.order)
    if (dynamicMenuId === menuId) result.push(...dynamicEntries)
    const terms = query.trim().toLowerCase().split(/\s+/).filter(term => term.length > 0)
    if (terms.length === 0) return result
    return result.filter(entry => {
      const searchText = ((entry.searchText ?? "") + " " + entry.label).toLowerCase()
      return terms.every(term => fuzzyMatch(searchText, term))
    })
  }

  function menuMessage(menuId: string, query: string): string {
    if (dynamicMenuId === menuId) {
      if (dynamicError.length > 0) return dynamicError
    }
    if (query.trim().length > 0) return "No matches"
    return menus[menuId]?.emptyLabel ?? "No entries"
  }

  function validateDynamicEntries(value, menuId): var {
    if (!Array.isArray(value)) fail("dynamic menu '" + menuId + "'", "expected an array")

    const result = []
    const ids = new Set()
    for (let index = 0; index < value.length; index++) {
      const path = "dynamic menu '" + menuId + "'[" + index + "]"
      const entry = value[index]
      requireObject(entry, path)
      if (typeof entry.id !== "string" || entry.id.length === 0) {
        fail(path + ".id", "expected a non-empty string")
      }
      if (ids.has(entry.id)) fail(path + ".id", "duplicate id '" + entry.id + "'")
      ids.add(entry.id)
      if (typeof entry.label !== "string" || entry.label.length === 0) {
        fail(path + ".label", "expected a non-empty string")
      }
      if (entry.icon !== undefined && typeof entry.icon !== "string") {
        fail(path + ".icon", "expected a string")
      }
      if (entry.searchText !== undefined && typeof entry.searchText !== "string") {
        fail(path + ".searchText", "expected a string")
      }
      requireObject(entry.action, path + ".action")
      if (entry.action.type === "command") {
        if (typeof entry.action.command !== "string" || entry.action.command.length === 0) {
          fail(path + ".action.command", "expected a non-empty command")
        }
      } else if (entry.action.type === "menu") {
        if (typeof entry.action.menu !== "string" || !menus[entry.action.menu]) {
          fail(path + ".action.menu", "unknown menu '" + entry.action.menu + "'")
        }
      } else if (entry.action.type === "dismiss") {
        // Informational entries close the menu when activated.
      } else {
        fail(path + ".action.type", "expected 'command', 'menu', or 'dismiss'")
      }
      result.push(Object.assign({
        "parent": menuId,
        "order": (index + 1) * 10
      }, clone(entry)))
    }
    return result
  }

  function showMenu(screen: string, nextHistory, menuId: string,
      loadedEntries, error: string): void {
    screenName = screen
    history = nextHistory
    currentMenu = menuId
    dynamicMenuId = menus[menuId]?.sourceCommand === undefined ? "" : menuId
    dynamicEntries = loadedEntries
    dynamicError = error
    openRevision++
    requested = true
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

    let loadedEntries = []
    let errorMessage = ""
    try {
      loadedEntries = validateDynamicEntries(
        parse(output, "dynamic menu '" + sourceMenuId + "'"),
        sourceMenuId)
    } catch (error) {
      errorMessage = "Could not load entries"
      console.error("Dynamic menu source rejected: " + String(error))
    }
    showMenu(sourceScreenName, sourceHistory, sourceMenuId,
      loadedEntries, errorMessage)
  }

  function focusedScreenName(): string {
    return Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? ""
  }

  function openForScreen(name: string, menu: string): bool {
    if (!ready || name.length === 0 || !menus[menu]) return false
    return enterMenu(name, [menu], menu)
  }

  function openOnFocusedScreen(menu: string): bool {
    return openForScreen(focusedScreenName(), menu)
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

  function toggleOnFocusedScreen(menu: string): bool {
    return toggleForScreen(focusedScreenName(), menu)
  }

  function close(): void {
    if (sourceLoading) {
      sourceCancelled = true
      dynamicSource.running = false
    }
    requested = false
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

    close()
    if (entry.action.type === "command") {
      Quickshell.execDetached(["bash", "-c", entry.action.command])
    }
  }
}
