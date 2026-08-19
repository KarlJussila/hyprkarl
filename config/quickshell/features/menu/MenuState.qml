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

      requireObject(entry.action, entryPath + ".action")
      if (entry.action.type === "command") {
        if (typeof entry.action.command !== "string" || entry.action.command.length === 0) {
          fail(entryPath + ".action.command", "expected a non-empty command")
        }
      } else if (entry.action.type === "menu") {
        if (typeof entry.action.menu !== "string" || !document.menus[entry.action.menu]) {
          fail(entryPath + ".action.menu", "unknown menu '" + entry.action.menu + "'")
        }
      } else {
        fail(entryPath + ".action.type", "expected 'command' or 'menu'")
      }
    }
  }

  function apply(document): void {
    values = document
    ready = true
    lastError = ""
    if (requested && !menus[currentMenu]) close()
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

  function entriesFor(menuId: string): var {
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
    return result
  }

  function focusedScreenName(): string {
    return Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? ""
  }

  function openForScreen(name: string, menu: string): bool {
    if (!ready || name.length === 0 || !menus[menu]) return false
    screenName = name
    history = [menu]
    currentMenu = menu
    requested = true
    return true
  }

  function openOnFocusedScreen(menu: string): bool {
    return openForScreen(focusedScreenName(), menu)
  }

  function toggleForScreen(name: string, menu: string): bool {
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
    requested = false
  }

  function back(): void {
    if (history.length <= 1) {
      close()
      return
    }
    const next = history.slice(0, -1)
    history = next
    currentMenu = next[next.length - 1]
  }

  function activate(entry): void {
    if (entry.action.type === "menu") {
      history = history.concat([entry.action.menu])
      currentMenu = entry.action.menu
      return
    }

    close()
    Quickshell.execDetached(["bash", "-lc", entry.action.command])
  }
}
