pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../config"

Item {
  id: root

  required property var descriptor
  required property string notificationImage
  required property real progress
  required property var theme

  readonly property bool hasNotificationImage: notificationImage.length > 0
  readonly property string kind: descriptor?.kind ?? "none"
  readonly property string value: descriptor?.value ?? ""
  readonly property bool visibleIcon: hasNotificationImage || kind !== "none"
  readonly property int iconSize: theme.notificationIconSize
  readonly property string imageSource: resolveImage(
    hasNotificationImage ? notificationImage : value)
  readonly property string componentSource: resolveComponent()

  function resolveImage(candidate): string {
    if (candidate.length === 0) return ""
    if (candidate.startsWith("/")) return "file://" + candidate
    if (candidate.startsWith("file:") || candidate.startsWith("image:")) {
      return candidate
    }
    return Quickshell.iconPath(candidate, true)
  }

  function resolveComponent(): string {
    if (kind !== "component") return ""
    if (descriptor.source.startsWith("builtin/")) {
      return Quickshell.shellPath("features/notifications/icons/"
        + descriptor.source.slice("builtin/".length))
    }
    return Paths.userUrl("quickshell/icons/"
      + descriptor.source.slice("user/".length))
  }

  function syncDrawing(): void {
    if (!drawing.item) return
    drawing.item.progress = progress
    drawing.item.theme = theme
  }

  function loadDrawing(): void {
    if (!drawing.active || componentSource.length === 0) return
    drawing.setSource(componentSource, {
      "progress": progress,
      "theme": theme
    })
  }

  onProgressChanged: syncDrawing()
  onThemeChanged: syncDrawing()
  onComponentSourceChanged: loadDrawing()
  Component.onCompleted: loadDrawing()

  visible: visibleIcon
  implicitWidth: visibleIcon ? iconSize : 0
  implicitHeight: visibleIcon ? iconSize : 0

  IconImage {
    anchors.fill: parent
    visible: root.hasNotificationImage || root.kind === "icon"
    source: root.imageSource
  }

  Text {
    anchors.centerIn: parent
    visible: !root.hasNotificationImage && root.kind === "glyph"
    text: root.value
    color: root.theme.foreground
    font.family: root.theme.uiFontFamily
    font.pixelSize: root.theme.notificationIconSize
    font.weight: root.theme.fontWeight
    font.styleName: root.theme.fontStyle
  }

  Loader {
    id: drawing

    anchors.fill: parent
    active: !root.hasNotificationImage && root.kind === "component"
    onActiveChanged: {
      if (active) root.loadDrawing()
    }
    onLoaded: root.syncDrawing()
  }
}
