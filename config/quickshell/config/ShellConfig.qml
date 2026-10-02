import QtQml
import Quickshell
import Quickshell.Io

// The shipped defaults with the personal override merged over them. Objects
// merge key by key; arrays and other values replace. Both files reload live.
QtObject {
  id: root

  readonly property var values: resolve(defaultFile.text(), personalFile.text())
  readonly property var bar: values.bar
  readonly property var osd: values.osd
  readonly property var notifications: values.notifications
  readonly property var userRoot: values.userRoot

  // Module choices latch at startup; changing them needs hk-shell restart.
  property var modules: ({})
  Component.onCompleted: modules = values.modules

  property FileView defaultFile: FileView {
    path: Quickshell.shellPath("../../defaults/shell.json")
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
  }

  property FileView personalFile: FileView {
    path: Paths.userPath("settings/shell.json")
    blockLoading: true
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
  }

  function isObject(value): bool {
    return value !== null && typeof value === "object" && !Array.isArray(value)
  }

  function merge(base, override): var {
    if (!isObject(base) || !isObject(override)) return override
    const result = Object.assign({}, base)
    for (const key of Object.keys(override)) {
      result[key] = merge(base[key], override[key])
    }
    return result
  }

  // A personal file that does not parse leaves the defaults running until it
  // is fixed, so a half-saved edit cannot take the shell down.
  function resolve(defaultText, personalText): var {
    const defaults = JSON.parse(defaultText)
    if (personalText.length === 0) return defaults
    try {
      return merge(defaults, JSON.parse(personalText))
    } catch (error) {
      console.error(`${personalFile.path}: ${error}`)
      return defaults
    }
  }
}
