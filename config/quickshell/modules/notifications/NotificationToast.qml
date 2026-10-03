pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import Quickshell.Widgets

ClippingRectangle {
  id: root

  required property var entry
  required property var notificationState
  required property var theme
  property bool sharpTopLeft: false
  property bool sharpTopRight: false
  property bool sharpBottomLeft: false
  property bool sharpBottomRight: false

  readonly property var sourceNotification: entry.source
  readonly property string appName: sourceNotification?.appName ?? entry.appName
  readonly property string summary: sourceNotification?.summary ?? entry.summary
  readonly property string body: sourceNotification?.body ?? entry.body
  // Bodies carry the spec's markup (<b>, <i>, <u>, <a>), which StyledText
  // renders. Images are dropped because any app can send a body and an <img>
  // would load whatever URL it names; plain newlines become breaks.
  readonly property string bodyMarkup: body
    .replace(/<img\b[^>]*>/gi, "")
    .replace(/\n/g, "<br>")
  readonly property string notificationImage: sourceNotification?.image ?? entry.image
  readonly property int urgency: sourceNotification?.urgency ?? entry.urgency
  readonly property real progress: sourceNotification
    ? notificationState.progressFor(sourceNotification)
    : entry.progress
  readonly property int timeout: sourceNotification
    ? notificationState.timeoutFor(sourceNotification)
    : entry.timeout
  readonly property bool compact: notificationState.compactFor(entry)
  readonly property var iconDescriptor: notificationState.iconFor(entry)

  implicitWidth: compact
    ? theme.notification.compactWidth
    : theme.notification.width
  implicitHeight: content.implicitHeight + theme.notification.padding * 2
  color: theme.surfaces.notification
  border.color: urgency === NotificationUrgency.Critical
    ? theme.palette.urgent
    : theme.palette.border
  border.width: theme.metrics.borderWidth
  radius: theme.notification.radius
  topLeftRadius: sharpTopLeft ? 0 : radius
  topRightRadius: sharpTopRight ? 0 : radius
  bottomLeftRadius: sharpBottomLeft ? 0 : radius
  bottomRightRadius: sharpBottomRight ? 0 : radius

  HoverHandler { id: hover }

  TapHandler {
    cursorShape: Qt.PointingHandCursor
    onTapped: root.notificationState.dismissEntry(root.entry)
  }

  Timer {
    id: expiryTimer

    interval: root.timeout
    running: !root.entry.closing && root.timeout > 0 && !hover.hovered
    onTriggered: root.notificationState.expire(root.entry)
  }

  Connections {
    target: root.sourceNotification

    function onClosed(): void {
      root.notificationState.sourceClosed(root.entry)
    }

    function restartExpiry(): void {
      if (root.timeout > 0 && !hover.hovered) expiryTimer.restart()
    }

    function onExpireTimeoutChanged(): void { restartExpiry() }
    function onSummaryChanged(): void { restartExpiry() }
    function onBodyChanged(): void { restartExpiry() }
    function onImageChanged(): void { restartExpiry() }
    function onAppIconChanged(): void { restartExpiry() }
    function onUrgencyChanged(): void { restartExpiry() }
    function onActionsChanged(): void { restartExpiry() }
    function onHintsChanged(): void { restartExpiry() }
  }

  ColumnLayout {
    id: content

    anchors.fill: parent
    anchors.margins: root.theme.notification.padding
    spacing: root.theme.notification.spacing

    RowLayout {
      Layout.fillWidth: true
      spacing: root.theme.notification.spacing

      NotificationIcon {
        descriptor: root.iconDescriptor
        notificationImage: root.notificationImage
        progress: root.progress
        theme: root.theme
      }

      ColumnLayout {
        id: message

        Layout.fillWidth: true
        spacing: 2

        Text {
          Layout.fillWidth: true
          text: root.summary
          color: root.theme.palette.foreground
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          maximumLineCount: 2
          elide: Text.ElideRight
          font.family: root.theme.typography.uiFamily
          font.pixelSize: root.theme.typography.bodySize
          font.weight: root.theme.typography.weight
          font.styleName: root.theme.typography.style
        }

        Text {
          Layout.fillWidth: true
          visible: text.length > 0
          text: root.bodyMarkup
          color: root.theme.palette.muted
          textFormat: Text.StyledText
          wrapMode: Text.Wrap
          maximumLineCount: 4
          elide: Text.ElideRight
          font.family: root.theme.typography.uiFamily
          font.pixelSize: root.theme.typography.bodySize
          font.weight: root.theme.typography.weight
          font.styleName: root.theme.typography.style
        }

      }
    }

    Rectangle {
      Layout.fillWidth: true
      visible: root.progress >= 0
      implicitHeight: root.theme.notification.progressHeight
      color: root.theme.palette.border
      radius: height / 2

      Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * root.progress / 100
        color: root.theme.palette.accent
        radius: parent.radius
      }
    }
  }
}
