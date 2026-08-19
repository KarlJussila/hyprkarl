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
    return shellConfig.notificationDefaultTimeout
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
    const overrides = shellConfig.notificationIconOverrides
    const appOverride = overrides[normalizedIconKey(appName)]
    if (appOverride) return appOverride

    const iconOverride = overrides[normalizedIconKey(appIcon)]
    if (iconOverride) return iconOverride

    if (appIcon.length > 0) {
      return { "kind": "icon", "value": appIcon }
    }

    const urgency = source?.urgency ?? entry.urgency
    return urgency === NotificationUrgency.Critical
      ? shellConfig.notificationCriticalIcon
      : shellConfig.notificationFallbackIcon
  }

  function compactFor(entry): bool {
    const appName = entry.source?.appName ?? entry.appName
    return shellConfig.notificationCompactApplications.indexOf(
      normalizedIconKey(appName)) !== -1
  }

  function makeEntry(notification): var {
    return {
      "serial": nextSerial++,
      "source": notification,
      "screenName": focusedScreenName(),
      "appName": notification.appName,
      "summary": notification.summary,
      "body": notification.body,
      "appIcon": notification.appIcon,
      "image": notification.image,
      "urgency": notification.urgency,
      "progress": progressFor(notification),
      "timeout": timeoutFor(notification),
      "synchronousKey": synchronousKey(notification),
      "glyph": "",
      "revealed": false,
      "remember": true
    }
  }

  function snapshot(entry): var {
    const source = entry.source
    return {
      "serial": nextSerial++,
      "source": null,
      "screenName": entry.screenName,
      "appName": source?.appName ?? entry.appName,
      "summary": source?.summary ?? entry.summary,
      "body": source?.body ?? entry.body,
      "appIcon": source?.appIcon ?? entry.appIcon,
      "image": source?.image ?? entry.image,
      "urgency": source?.urgency ?? entry.urgency,
      "progress": source ? progressFor(source) : entry.progress,
      "timeout": source ? timeoutFor(source) : entry.timeout,
      "synchronousKey": "",
      "glyph": entry.glyph,
      "revealed": false,
      "remember": true
    }
  }

  function removeEntry(entry): void {
    visibleNotifications = visibleNotifications.filter(candidate =>
      candidate.serial !== entry.serial)
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
    const overflow = entries.splice(shellConfig.notificationMaxVisible)
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
    if (shellConfig.notificationIgnoredApplications.indexOf(appName) !== -1) return

    if (silenced) {
      remember(entry)
      return
    }

    replaceSynchronous(entry)
    notification.tracked = true
    present(entry)
  }

  function sourceClosed(entry): void {
    removeEntry(entry)
  }

  function expire(entry): void {
    remember(entry)
    removeEntry(entry)
    closeSource(entry, true)
  }

  function dismissEntry(entry): void {
    remember(entry)
    removeEntry(entry)
    closeSource(entry, false)
  }

  function dismissLatest(): void {
    if (visibleNotifications.length > 0) dismissEntry(visibleNotifications[0])
  }

  function dismissAll(): void {
    if (visibleNotifications.length === 0) return

    remember(visibleNotifications[0])
    const entries = visibleNotifications
    visibleNotifications = []
    for (const entry of entries) closeSource(entry, false)
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
    present({
      "serial": nextSerial++,
      "source": null,
      "screenName": focusedScreenName(),
      "appName": "Hyprkarl",
      "summary": summary,
      "body": "",
      "appIcon": "",
      "image": "",
      "urgency": NotificationUrgency.Normal,
      "progress": -1,
      "timeout": shellConfig.notificationStatusTimeout,
      "synchronousKey": "",
      "glyph": glyph,
      "revealed": false,
      "remember": false
    })
  }

  function toggleSilenced(): void {
    silenced = !silenced
    showStatus(
      silenced ? "Silenced notifications" : "Enabled notifications",
      silenced ? "󰂛" : "󰂚"
    )
  }
}
