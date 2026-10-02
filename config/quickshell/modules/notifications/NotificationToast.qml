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
    ? theme.notificationCompactWidth
    : theme.notificationWidth
  implicitHeight: content.implicitHeight + theme.notificationPadding * 2
  color: theme.notificationSurface
  border.color: urgency === NotificationUrgency.Critical
    ? theme.urgent
    : theme.border
  border.width: theme.borderWidth
  radius: theme.notificationRadius
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
    anchors.margins: root.theme.notificationPadding
    spacing: root.theme.notificationSpacing

    RowLayout {
      Layout.fillWidth: true
      spacing: root.theme.notificationSpacing

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
          color: root.theme.foreground
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          maximumLineCount: 2
          elide: Text.ElideRight
          font.family: root.theme.uiFontFamily
          font.pixelSize: root.theme.bodyFontSize
          font.weight: root.theme.fontWeight
          font.styleName: root.theme.fontStyle
        }

        Text {
          Layout.fillWidth: true
          visible: text.length > 0
          text: root.body
          color: root.theme.muted
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          maximumLineCount: 4
          elide: Text.ElideRight
          font.family: root.theme.uiFontFamily
          font.pixelSize: root.theme.bodyFontSize
          font.weight: root.theme.fontWeight
          font.styleName: root.theme.fontStyle
        }

      }
    }

    Rectangle {
      Layout.fillWidth: true
      visible: root.progress >= 0
      implicitHeight: root.theme.notificationProgressHeight
      color: root.theme.border
      radius: height / 2

      Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * root.progress / 100
        color: root.theme.accent
        radius: parent.radius
      }
    }
  }
}
