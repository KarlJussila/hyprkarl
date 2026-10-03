import QtQml
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications

QtObject {
  id: root

  required property var shellConfig

  property var visibleNotifications: []
  property var lastDismissed: null
  property bool silenced: false
  property int nextSerial: 1

  property NotificationServer server: NotificationServer {
    keepOnReload: true
    bodySupported: true
    bodyMarkupSupported: false
    bodyHyperlinksSupported: false
    bodyImagesSupported: false
    actionsSupported: false
    actionIconsSupported: false
    imageSupported: true
    inlineReplySupported: false
    persistenceSupported: false

    onNotification: notification => root.receive(notification)
  }

  property IpcHandler ipc: IpcHandler {
    target: "notifications"

    function dismiss(): bool {
      root.dismissLatest()
      return true
    }

    function dismissAll(): bool {
      root.dismissAll()
      return true
    }

    function toggleSilenced(): bool {
      root.toggleSilenced()
      return true
    }

    function restore(): bool {
      root.restoreLatest()
      return true
    }
  }

  function focusedScreenName(): string {
    return Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? ""
  }

  function screenExists(name): bool {
    return Quickshell.screens.some(screen => screen.name === name)
  }

  function resolvedScreenName(name): string {
    if (screenExists(name)) return name
    return Quickshell.screens[0]?.name ?? ""
  }

  function entriesForScreen(name): var {
    return visibleNotifications.filter(entry =>
      resolvedScreenName(entry.screenName) === name)
  }

  function timeoutFor(notification): int {
    if (notification.urgency === NotificationUrgency.Critical) return 0
    if (notification.expireTimeout === 0) return 0
    if (notification.expireTimeout > 0) return notification.expireTimeout
    return shellConfig.notifications.defaultTimeout
  }

  function progressFor(notification): real {
    const value = notification.hints["value"]
    if (value === undefined || value === null || isNaN(Number(value))) return -1
    return Math.max(0, Math.min(100, Number(value)))
  }

  function synchronousKey(notification): string {
    const value = notification.hints["x-canonical-private-synchronous"]
    return value === undefined || value === null ? "" : String(value)
  }

  function normalizedIconKey(value): string {
    return String(value ?? "").trim().toLowerCase()
  }

  function iconFor(entry): var {
    if (entry.glyph.length > 0) {
      return { "kind": "glyph", "value": entry.glyph }
    }

    const source = entry.source
    const appName = source?.appName ?? entry.appName
    const appIcon = source?.appIcon ?? entry.appIcon
    const overrides = shellConfig.notifications.iconOverrides
    const appOverride = overrides[normalizedIconKey(appName)]
    if (appOverride) return appOverride

    const iconOverride = overrides[normalizedIconKey(appIcon)]
    if (iconOverride) return iconOverride

    if (appIcon.length > 0) {
      return { "kind": "icon", "value": appIcon }
    }

    const urgency = source?.urgency ?? entry.urgency
    return urgency === NotificationUrgency.Critical
      ? shellConfig.notifications.criticalIcon
      : shellConfig.notifications.fallbackIcon
  }

  function compactFor(entry): bool {
    const appName = entry.source?.appName ?? entry.appName
    return shellConfig.notifications.compactApplications.indexOf(
      normalizedIconKey(appName)) !== -1
  }

  // What a toast shows. An entry copies it, so it can be restored after its
  // notification is gone; a toast reads the live notification while it lasts.
  function contentOf(notification): var {
    return {
      "appName": notification.appName,
      "summary": notification.summary,
      "body": notification.body,
      "appIcon": notification.appIcon,
      "image": notification.image,
      "urgency": notification.urgency,
      "progress": progressFor(notification),
      "timeout": timeoutFor(notification)
    }
  }

  function newEntry(screenName, content): var {
    return Object.assign({
      "serial": nextSerial++,
      "source": null,
      "screenName": screenName,
      "synchronousKey": "",
      "glyph": "",
      "revealed": false,
      "closing": false,
      "closeMode": "",
      "remember": true
    }, content)
  }

  function makeEntry(notification): var {
    return newEntry(focusedScreenName(), Object.assign(contentOf(notification), {
      "source": notification,
      "synchronousKey": synchronousKey(notification)
    }))
  }

  function snapshot(entry): var {
    const content = entry.source ? contentOf(entry.source) : {
      "appName": entry.appName,
      "summary": entry.summary,
      "body": entry.body,
      "appIcon": entry.appIcon,
      "image": entry.image,
      "urgency": entry.urgency,
      "progress": entry.progress,
      "timeout": entry.timeout
    }
    content.glyph = entry.glyph
    return newEntry(entry.screenName, content)
  }

  function removeEntry(entry): void {
    visibleNotifications = visibleNotifications.filter(candidate =>
      candidate.serial !== entry.serial)
  }

  function beginRemoval(entry, shouldRemember, closeMode): void {
    const current = visibleNotifications.find(candidate =>
      candidate.serial === entry.serial)
    if (!current || current.closing) return

    if (shouldRemember) remember(current)
    const closing = Object.assign({}, current, {
      "closing": true,
      "closeMode": closeMode
    })
    visibleNotifications = visibleNotifications.map(candidate =>
      candidate.serial === closing.serial ? closing : candidate)
  }

  function finishRemoval(entry): void {
    const current = visibleNotifications.find(candidate =>
      candidate.serial === entry.serial)
    if (!current || !current.closing) return

    removeEntry(current)
    if (current.closeMode === "expire") closeSource(current, true)
    else if (current.closeMode === "dismiss") closeSource(current, false)
  }

  function remember(entry): void {
    if (entry.remember !== false) lastDismissed = snapshot(entry)
  }

  function closeSource(entry, expired): void {
    const source = entry.source
    if (!source) return
    if (expired) source.expire()
    else source.dismiss()
  }

  function present(entry): void {
    const entries = [entry].concat(visibleNotifications)
    const overflow = entries.splice(shellConfig.notifications.maxVisible)
    visibleNotifications = entries

    for (const hidden of overflow) {
      remember(hidden)
      closeSource(hidden, true)
    }
  }

  function replaceSynchronous(entry): void {
    if (entry.synchronousKey.length === 0) return

    const previous = visibleNotifications.find(candidate =>
      candidate.synchronousKey === entry.synchronousKey
        && candidate.appName === entry.appName)
    if (!previous) return

    removeEntry(previous)
    closeSource(previous, true)
  }

  function receive(notification): void {
    const entry = makeEntry(notification)
    const appName = normalizedIconKey(notification.appName)
    if (shellConfig.notifications.ignoredApplications.indexOf(appName) !== -1) return

    if (silenced) {
      remember(entry)
      return
    }

    replaceSynchronous(entry)
    notification.tracked = true
    present(entry)
  }

  function sourceClosed(entry): void {
    beginRemoval(entry, false, "")
  }

  function expire(entry): void {
    beginRemoval(entry, true, "expire")
  }

  function dismissEntry(entry): void {
    beginRemoval(entry, true, "dismiss")
  }

  function dismissLatest(): void {
    if (visibleNotifications.length > 0) dismissEntry(visibleNotifications[0])
  }

  function dismissAll(): void {
    const entries = visibleNotifications.filter(entry => !entry.closing)
    if (entries.length === 0) return

    remember(entries[0])
    for (const entry of entries) beginRemoval(entry, false, "dismiss")
  }

  function restoreLatest(): void {
    if (!lastDismissed) return

    const entry = lastDismissed
    entry.serial = nextSerial++
    entry.screenName = focusedScreenName()
    lastDismissed = null
    present(entry)
  }

  function showStatus(summary, glyph): void {
    present(newEntry(focusedScreenName(), {
      "appName": "Hyprkarl",
      "summary": summary,
      "body": "",
      "appIcon": "",
      "image": "",
      "urgency": NotificationUrgency.Normal,
      "progress": -1,
      "timeout": shellConfig.notifications.statusTimeout,
      "glyph": glyph,
      "remember": false
    }))
  }

  function toggleSilenced(): void {
    silenced = !silenced
    showStatus(
      silenced ? "Silenced notifications" : "Enabled notifications",
      silenced ? "󰂛" : "󰂚"
    )
  }
}
