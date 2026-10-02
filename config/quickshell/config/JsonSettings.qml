import QtQml
import Quickshell.Io

// A shipped JSON file with an optional personal file merged over it. Objects
// merge key by key; arrays and other values replace. Both files reload live.
QtObject {
  id: root

  required property string defaultPath
  required property string personalPath
  readonly property var values: resolve(defaultFile.text(), personalFile.text())

  property FileView defaultFile: FileView {
    path: root.defaultPath
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
  }

  property FileView personalFile: FileView {
    path: root.personalPath
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
      console.error(`${personalPath}: ${error}`)
      return defaults
    }
  }
}
