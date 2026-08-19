import QtQml
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  readonly property url defaultPath: Quickshell.shellPath("../../defaults/shell.json")
  readonly property url userPath: Quickshell.shellPath("../../user/shell.json")
  property var values: ({})
  property bool ready: false
  property url sourcePath: defaultPath
  property string lastError: ""
  property bool loading: false
  property bool defaultResolved: false
  property bool userResolved: false
  property string defaultReadError: ""
  property string userReadError: ""
  property bool userMissing: true

  readonly property var bar: values.bar ?? ({})
  readonly property var osd: values.osd ?? ({})
  readonly property var notifications: values.notifications ?? ({})
  readonly property string notificationEdge: notifications.edge ?? "top"
  readonly property string notificationSide: notifications.side ?? "right"
  readonly property int notificationGap: notifications.gap ?? 0
  readonly property int notificationSideMargin: notifications.sideMargin ?? 0
  readonly property int notificationDefaultTimeout: notifications.defaultTimeout ?? 5000
  readonly property int notificationStatusTimeout: notifications.statusTimeout ?? 2000
  readonly property int notificationMaxVisible: notifications.maxVisible ?? 5
  readonly property var notificationIconOverrides: notifications.iconOverrides ?? ({})
  readonly property var notificationFallbackIcon: notifications.fallbackIcon
    ?? ({ "kind": "glyph", "value": "󰂚" })
  readonly property var notificationCriticalIcon: notifications.criticalIcon
    ?? ({ "kind": "glyph", "value": "󰀦" })
  readonly property var notificationIgnoredApplications:
    notifications.ignoredApplications ?? []
  readonly property var notificationCompactApplications:
    notifications.compactApplications ?? []
  readonly property string osdEdge: osd.edge ?? "bottom"
  readonly property int osdMargin: osd.margin ?? 40
  readonly property int osdTimeout: osd.timeout ?? 2000
  readonly property int osdMediaTimeout: osd.mediaTimeout ?? 3000
  readonly property string edge: bar.edge ?? "top"
  readonly property bool exclusive: bar.exclusive ?? true
  readonly property var layout: bar.layout ?? ({})
  readonly property var start: layout.start ?? []
  readonly property var center: layout.center ?? ({})
  readonly property var centerBefore: center.before ?? []
  readonly property var centerAnchor: center.anchor ?? null
  readonly property var centerAnchorInstances: centerAnchor ? [centerAnchor] : []
  readonly property var centerAfter: center.after ?? []
  readonly property var end: layout.end ?? []
  readonly property var widgetInstances: start.concat(
    centerBefore, centerAnchorInstances, centerAfter, end)
  readonly property var commandProviders: widgetInstances.filter(
    widget => widget.kind === "command" && widget.command !== undefined)

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

  function fail(path, message): void {
    throw new Error(path + ": " + message)
  }

  function requireObject(value, path): void {
    if (value === null || typeof value !== "object" || Array.isArray(value)) {
      fail(path, "expected an object")
    }
  }

  function requireArray(value, path): void {
    if (!Array.isArray(value)) {
      fail(path, "expected an array")
    }
  }

  function isObject(value): bool {
    return value !== null && typeof value === "object" && !Array.isArray(value)
  }

  function clone(value): var {
    if (Array.isArray(value)) {
      return value.map(entry => clone(entry))
    }
    if (isObject(value)) {
      const copy = {}
      for (const key of Object.keys(value)) {
        copy[key] = clone(value[key])
      }
      return copy
    }
    return value
  }

  function merge(base, override): var {
    if (!isObject(base) || !isObject(override)) {
      return clone(override)
    }

    const result = clone(base)
    for (const key of Object.keys(override)) {
      result[key] = key in result ? merge(result[key], override[key]) : clone(override[key])
    }
    return result
  }

  function validateWidget(widget, path, ids): void {
    requireObject(widget, path)
    if (typeof widget.id !== "string" || widget.id.length === 0) {
      fail(path + ".id", "expected a non-empty string")
    }
    if (ids.indexOf(widget.id) !== -1) {
      fail(path + ".id", "duplicate widget id '" + widget.id + "'")
    }
    ids.push(widget.id)

    if (widget.kind === "command") {
      validateCommandWidget(widget, path)
    }
  }

  function validateCommandWidget(widget, path): void {
    const hasProvider = widget.command !== undefined
    if (hasProvider
        && (typeof widget.command !== "string" || widget.command.length === 0)) {
      fail(path + ".command", "expected a non-empty string")
    }
    if (!hasProvider
        && !(typeof widget.text === "string" && widget.text.length > 0)
        && !(typeof widget.icon === "string" && widget.icon.length > 0)) {
      fail(path, "expected text or an icon when no provider command is set")
    }
    const mode = widget.mode ?? "poll"
    if (hasProvider && mode !== "poll" && mode !== "stream") {
      fail(path + ".mode", "expected 'poll' or 'stream'")
    }
    if (hasProvider && mode === "poll"
        && (!Number.isInteger(widget.interval) || widget.interval <= 0)) {
      fail(path + ".interval", "expected a positive integer in poll mode")
    }
    if (hasProvider && mode === "stream" && widget.interval !== undefined) {
      fail(path + ".interval", "not used in stream mode")
    }
    if (!hasProvider) {
      for (const field of ["mode", "interval", "output"]) {
        if (widget[field] !== undefined) {
          fail(path + "." + field, "requires a provider command")
        }
      }
    }
    if (widget.output !== undefined
        && widget.output !== "text"
        && widget.output !== "json") {
      fail(path + ".output", "expected 'text' or 'json'")
    }
    for (const field of [
      "icon",
      "text",
      "tooltip",
      "primaryCommand",
      "secondaryCommand",
      "tertiaryCommand"
    ]) {
      if (widget[field] !== undefined && typeof widget[field] !== "string") {
        fail(path + "." + field, "expected a string")
      }
    }
    if (widget.state !== undefined
        && ["normal", "muted", "accent", "warning", "urgent"]
          .indexOf(widget.state) === -1) {
      fail(path + ".state",
        "expected 'normal', 'muted', 'accent', 'warning', or 'urgent'")
    }
  }

  function validateWidgets(widgets, path, ids): void {
    requireArray(widgets, path)
    for (let index = 0; index < widgets.length; index++) {
      validateWidget(widgets[index], path + "[" + index + "]", ids)
    }
  }

  function validateNotificationIcon(icon, path): void {
    requireObject(icon, path)
    const kinds = ["component", "glyph", "icon", "none"]
    if (typeof icon.kind !== "string" || kinds.indexOf(icon.kind) === -1) {
      fail(path + ".kind", "expected component, glyph, icon, or none")
    }
    if ((icon.kind === "glyph" || icon.kind === "icon")
        && (typeof icon.value !== "string" || icon.value.length === 0)) {
      fail(path + ".value", "expected a non-empty string")
    }
    if (icon.kind === "component"
        && (typeof icon.source !== "string"
          || !/^(builtin|user)\/[A-Za-z0-9._-]+\.qml$/.test(icon.source))) {
      fail(path + ".source",
        "expected builtin/<file>.qml or user/<file>.qml")
    }
  }

  function validate(document, path): void {
    requireObject(document, path)
    if (document.version !== 1) {
      fail(path + ".version", "unsupported shell configuration version '" + document.version + "'")
    }

    requireObject(document.osd, path + ".osd")
    if (document.osd.edge !== "top" && document.osd.edge !== "bottom") {
      fail(path + ".osd.edge", "expected 'top' or 'bottom'")
    }
    for (const field of ["margin", "timeout", "mediaTimeout"]) {
      const value = document.osd[field]
      if (!Number.isInteger(value) || value < 0) {
        fail(path + ".osd." + field, "expected a non-negative integer")
      }
    }

    requireObject(document.notifications, path + ".notifications")
    if (document.notifications.edge !== "bar"
        && document.notifications.edge !== "top"
        && document.notifications.edge !== "bottom") {
      fail(path + ".notifications.edge", "expected 'bar', 'top', or 'bottom'")
    }
    if (document.notifications.side !== "left"
        && document.notifications.side !== "right") {
      fail(path + ".notifications.side", "expected 'left' or 'right'")
    }
    for (const field of ["gap", "sideMargin", "defaultTimeout", "statusTimeout"]) {
      const value = document.notifications[field]
      if (!Number.isInteger(value) || value < 0) {
        fail(path + ".notifications." + field, "expected a non-negative integer")
      }
    }
    if (!Number.isInteger(document.notifications.maxVisible)
        || document.notifications.maxVisible < 1) {
      fail(path + ".notifications.maxVisible", "expected a positive integer")
    }
    validateNotificationIcon(
      document.notifications.fallbackIcon,
      path + ".notifications.fallbackIcon")
    validateNotificationIcon(
      document.notifications.criticalIcon,
      path + ".notifications.criticalIcon")
    requireObject(
      document.notifications.iconOverrides,
      path + ".notifications.iconOverrides")
    for (const key of Object.keys(document.notifications.iconOverrides)) {
      if (key !== key.toLowerCase()) {
        fail(path + ".notifications.iconOverrides",
          "keys must be lowercase app or icon names")
      }
      validateNotificationIcon(
        document.notifications.iconOverrides[key],
        path + ".notifications.iconOverrides." + key)
    }
    for (const field of ["ignoredApplications", "compactApplications"]) {
      const entries = document.notifications[field]
      requireArray(entries, path + ".notifications." + field)
      for (let index = 0; index < entries.length; index++) {
        if (typeof entries[index] !== "string"
            || entries[index].length === 0
            || entries[index] !== entries[index].toLowerCase()) {
          fail(path + ".notifications." + field + "[" + index + "]",
            "expected a non-empty lowercase application name")
        }
      }
    }

    requireObject(document.bar, path + ".bar")
    if (document.bar.edge !== "top" && document.bar.edge !== "bottom") {
      fail(path + ".bar.edge", "version 1 supports only 'top' and 'bottom'")
    }
    if (typeof document.bar.exclusive !== "boolean") {
      fail(path + ".bar.exclusive", "expected a boolean")
    }

    const layout = document.bar.layout
    requireObject(layout, path + ".bar.layout")
    requireObject(layout.center, path + ".bar.layout.center")

    const ids = []
    validateWidgets(layout.start, path + ".bar.layout.start", ids)
    validateWidgets(layout.center.before, path + ".bar.layout.center.before", ids)
    if (layout.center.anchor !== null && layout.center.anchor !== undefined) {
      validateWidget(layout.center.anchor, path + ".bar.layout.center.anchor", ids)
    }
    validateWidgets(layout.center.after, path + ".bar.layout.center.after", ids)
    validateWidgets(layout.end, path + ".bar.layout.end", ids)
  }

  function parseJson(text, path): var {
    let document
    try {
      document = JSON.parse(text)
    } catch (error) {
      fail(path, "invalid JSON (" + error + ")")
    }
    return document
  }

  function parseDefault(text): var {
    const document = parseJson(text, defaultPath)
    validate(document, defaultPath)
    return document
  }

  function parseOverride(text): var {
    const document = parseJson(text, userPath)
    requireObject(document, userPath)
    if (document.version !== 1) {
      fail(userPath + ".version", "unsupported shell configuration version '" + document.version + "'")
    }
    if (document.bar !== undefined) {
      requireObject(document.bar, userPath + ".bar")
    }
    if (document.osd !== undefined) {
      requireObject(document.osd, userPath + ".osd")
    }
    if (document.notifications !== undefined) {
      requireObject(document.notifications, userPath + ".notifications")
    }
    return document
  }

  function findWidget(layout, id): var {
    const sections = ["start", "center.before", "center.anchor", "center.after", "end"]
    for (const section of sections) {
      if (section === "center.anchor") {
        if (layout.center.anchor && layout.center.anchor.id === id) {
          return { "section": section, "index": 0, "widget": layout.center.anchor }
        }
        continue
      }

      const widgets = section === "start" ? layout.start
        : section === "center.before" ? layout.center.before
        : section === "center.after" ? layout.center.after
        : layout.end
      for (let index = 0; index < widgets.length; index++) {
        if (widgets[index].id === id) {
          return { "section": section, "index": index, "widget": widgets[index] }
        }
      }
    }
    return null
  }

  function sectionWidgets(layout, section, path): var {
    if (section === "start") return layout.start
    if (section === "center.before") return layout.center.before
    if (section === "center.after") return layout.center.after
    if (section === "end") return layout.end
    if (section === "center.anchor") return null
    fail(path, "unknown layout section '" + section + "'")
  }

  function takeWidget(layout, found): var {
    if (found.section === "center.anchor") {
      layout.center.anchor = null
    } else {
      sectionWidgets(layout, found.section, "layout section").splice(found.index, 1)
    }
    return found.widget
  }

  function replaceWidget(layout, found, widget): void {
    if (found.section === "center.anchor") {
      layout.center.anchor = widget
    } else {
      sectionWidgets(layout, found.section, "layout section")[found.index] = widget
    }
  }

  function placeWidget(layout, widget, operation, path): void {
    if (typeof operation.section !== "string") {
      fail(path + ".section", "expected a layout section")
    }
    if (operation.before !== undefined && operation.after !== undefined) {
      fail(path, "'before' and 'after' are mutually exclusive")
    }

    const widgets = sectionWidgets(layout, operation.section, path + ".section")
    if (operation.section === "center.anchor") {
      if (operation.before !== undefined || operation.after !== undefined) {
        fail(path, "the center anchor does not accept 'before' or 'after'")
      }
      if (layout.center.anchor !== null && layout.center.anchor !== undefined) {
        fail(path + ".section", "center.anchor is already occupied by '" + layout.center.anchor.id + "'")
      }
      layout.center.anchor = widget
      return
    }

    const neighbor = operation.before !== undefined ? operation.before : operation.after
    if (neighbor === undefined) {
      widgets.push(widget)
      return
    }
    if (typeof neighbor !== "string" || neighbor.length === 0) {
      fail(path + (operation.before !== undefined ? ".before" : ".after"), "expected a widget id")
    }

    const neighborIndex = widgets.findIndex(entry => entry.id === neighbor)
    if (neighborIndex === -1) {
      fail(path, "target widget '" + neighbor + "' is not in section '" + operation.section + "'")
    }
    widgets.splice(neighborIndex + (operation.after !== undefined ? 1 : 0), 0, widget)
  }

  function requireOperationId(operation, path): string {
    if (typeof operation.id !== "string" || operation.id.length === 0) {
      fail(path + ".id", "expected a widget id")
    }
    return operation.id
  }

  function applyLayoutEdits(document, edits, path): void {
    requireArray(edits, path)
    const layout = document.bar.layout

    for (let index = 0; index < edits.length; index++) {
      const operation = edits[index]
      const operationPath = path + "[" + index + "]"
      requireObject(operation, operationPath)

      if (operation.op === "insert") {
        requireObject(operation.widget, operationPath + ".widget")
        if (typeof operation.widget.id !== "string" || operation.widget.id.length === 0) {
          fail(operationPath + ".widget.id", "expected a non-empty string")
        }
        if (findWidget(layout, operation.widget.id)) {
          fail(operationPath + ".widget.id", "duplicate widget id '" + operation.widget.id + "'")
        }
        placeWidget(layout, clone(operation.widget), operation, operationPath)
        continue
      }

      const id = requireOperationId(operation, operationPath)
      const found = findWidget(layout, id)
      if (!found) {
        fail(operationPath + ".id", "unknown widget id '" + id + "'")
      }

      if (operation.op === "remove") {
        takeWidget(layout, found)
      } else if (operation.op === "move") {
        placeWidget(layout, takeWidget(layout, found), operation, operationPath)
      } else if (operation.op === "override") {
        requireObject(operation.set, operationPath + ".set")
        if (operation.set.id !== undefined || operation.set.kind !== undefined) {
          fail(operationPath + ".set", "cannot change a widget's 'id' or 'kind'")
        }
        replaceWidget(layout, found, merge(found.widget, operation.set))
      } else {
        fail(operationPath + ".op", "expected 'insert', 'move', 'override', or 'remove'")
      }
    }
  }

  function resolve(defaultDocument, overrideDocument): var {
    const userValues = clone(overrideDocument)
    const edits = userValues.bar?.layoutEdits ?? []
    if (userValues.bar) delete userValues.bar.layoutEdits

    const document = merge(defaultDocument, userValues)
    applyLayoutEdits(document, edits, userPath + ".bar.layoutEdits")
    validate(document, userPath + " (effective)")
    return document
  }

  function apply(document, path): void {
    values = document
    sourcePath = path
    lastError = ""
    ready = true
  }

  function loadSelected(): void {
    if (!defaultResolved || !userResolved) return
    if (loading) return
    loading = true

    try {
      if (defaultReadError.length > 0 || !defaultSource.loaded) {
        fail(defaultPath, "could not read shipped default (" + defaultReadError + ")")
      }
      const defaultDocument = parseDefault(defaultSource.text())
      if (userMissing) {
        apply(defaultDocument, defaultPath)
      } else {
        try {
          if (userReadError.length > 0 || !userSource.loaded) {
            fail(userPath, "could not read user configuration (" + userReadError + ")")
          }
          const overrideDocument = parseOverride(userSource.text())
          apply(resolve(defaultDocument, overrideDocument), userPath)
        } catch (error) {
          const message = String(error)
          console.error("Shell configuration rejected: " + message)
          if (!ready) apply(defaultDocument, defaultPath)
          lastError = message
        }
      }
    } catch (error) {
      lastError = String(error)
      console.error("Shell configuration failed: " + lastError)
      if (!ready) throw error
    } finally {
      loading = false
    }
  }
}
