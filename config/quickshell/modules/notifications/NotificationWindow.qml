pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  required property var output
  required property var notificationState
  required property var position
  required property var shellConfig
  required property var theme

  readonly property string resolvedEdge: position.edge
  readonly property real surfaceExtent: position.extent ?? 0
  readonly property var screenEntries:
    notificationState.entriesForScreen(output.name)
  readonly property var entries: resolvedEdge === "top"
    ? screenEntries.slice().reverse()
    : screenEntries
  readonly property bool touchesSurface: surfaceExtent !== 0
    && position.connected === true
    && shellConfig.notifications.gap === 0
  readonly property bool touchesScreenSide:
    shellConfig.notifications.sideMargin === 0
  readonly property bool touchesScreenEdge: surfaceExtent === 0
    && shellConfig.notifications.gap === 0
  readonly property bool touchesAnchorCorner: touchesScreenSide
    && (touchesScreenEdge
      || (touchesSurface && position.reachesSide === true))
  readonly property real edgeOffset: surfaceExtent
    + shellConfig.notifications.gap
    - (touchesSurface ? theme.metrics.borderWidth : 0)
  readonly property bool connectedStack: theme.notification.stackSpacing === 0
  // The window takes the toasts' full heights rather than the animated stack's,
  // so it resizes once when a toast arrives and once after one has collapsed
  // instead of on every frame; the mask keeps the empty part click-through.
  readonly property real fullHeight: {
    const toasts = stack.children.filter(child => child.toastHeight !== undefined)
    return toasts.reduce((sum, child) => sum + child.toastHeight, 0)
      + stack.spacing * Math.max(0, toasts.length - 1)
  }

  visible: entries.length > 0
  screen: output
  color: "transparent"
  focusable: false
  aboveWindows: true
  exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0
  implicitWidth: Math.min(
    theme.notification.width,
    output.width - shellConfig.notifications.sideMargin)
  implicitHeight: fullHeight
  mask: Region { item: stack }

  anchors.top: resolvedEdge === "top"
  anchors.bottom: resolvedEdge === "bottom"
  anchors.left: shellConfig.notifications.side === "left"
  anchors.right: shellConfig.notifications.side === "right"
  margins.top: anchors.top ? edgeOffset : 0
  margins.bottom: anchors.bottom ? edgeOffset : 0
  margins.left: anchors.left ? shellConfig.notifications.sideMargin : 0
  margins.right: anchors.right ? shellConfig.notifications.sideMargin : 0

  WlrLayershell.namespace: "hyprkarl-quickshell-notifications"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  Column {
    id: stack

    anchors.top: root.resolvedEdge === "top" ? parent.top : undefined
    anchors.bottom: root.resolvedEdge === "bottom" ? parent.bottom : undefined
    width: root.width
    spacing: root.connectedStack
      ? -root.theme.metrics.borderWidth
      : root.theme.notification.stackSpacing

    Repeater {
      model: ScriptModel {
        values: root.entries
        objectProp: "serial"
      }

      Item {
        id: delegate

        required property var modelData
        required property int index

        readonly property bool edgeAdjacent: root.resolvedEdge === "top"
          ? index === 0
          : index === root.entries.length - 1
        readonly property bool touchesPrevious: root.connectedStack && index > 0
        readonly property bool touchesNext: root.connectedStack
          && index < root.entries.length - 1
        readonly property int toastWidth: root.notificationState.compactFor(modelData)
          ? root.theme.notification.compactWidth
          : root.theme.notification.width
        readonly property bool previousCoversOuterCorner: touchesPrevious
          && (root.notificationState.compactFor(root.entries[index - 1])
            ? root.theme.notification.compactWidth
            : root.theme.notification.width) >= toastWidth
        readonly property bool nextCoversOuterCorner: touchesNext
          && (root.notificationState.compactFor(root.entries[index + 1])
            ? root.theme.notification.compactWidth
            : root.theme.notification.width) >= toastWidth
        readonly property real toastHeight: toast.implicitHeight
        property real reveal: modelData.revealed ? 1 : 0

        width: stack.width
        height: reveal * toast.implicitHeight
        clip: true

        Behavior on reveal {
          NumberAnimation {
            duration: root.theme.notification.transitionDuration
            easing.type: Easing.OutCubic
          }
        }

        Timer {
          id: removalTimer

          interval: root.theme.notification.transitionDuration
          onTriggered: root.notificationState.finishRemoval(delegate.modelData)
        }

        onModelDataChanged: {
          if (modelData.closing) {
            reveal = 0
            removalTimer.restart()
          }
        }

        Component.onCompleted: {
          if (modelData.closing) {
            reveal = 0
            removalTimer.start()
          } else if (!modelData.revealed) {
            modelData.revealed = true
            reveal = 1
          }
        }

        NotificationToast {
          id: toast

          anchors.top: root.resolvedEdge === "top" ? parent.top : undefined
          anchors.bottom: root.resolvedEdge === "bottom" ? parent.bottom : undefined
          anchors.left: root.shellConfig.notifications.side === "left"
            ? parent.left
            : undefined
          anchors.right: root.shellConfig.notifications.side === "right"
            ? parent.right
            : undefined
          entry: parent.modelData
          notificationState: root.notificationState
          theme: root.theme
          opacity: parent.reveal
          sharpTopLeft: (parent.touchesPrevious
              && (root.shellConfig.notifications.side === "left"
                || parent.previousCoversOuterCorner))
            || (parent.edgeAdjacent
              && root.touchesAnchorCorner
              && root.resolvedEdge === "top"
              && root.shellConfig.notifications.side === "left")
          sharpTopRight: (parent.touchesPrevious
              && (root.shellConfig.notifications.side === "right"
                || parent.previousCoversOuterCorner))
            || (parent.edgeAdjacent
              && root.touchesAnchorCorner
              && root.resolvedEdge === "top"
              && root.shellConfig.notifications.side === "right")
          sharpBottomLeft: (parent.touchesNext
              && (root.shellConfig.notifications.side === "left"
                || parent.nextCoversOuterCorner))
            || (parent.edgeAdjacent
              && root.touchesAnchorCorner
              && root.resolvedEdge === "bottom"
              && root.shellConfig.notifications.side === "left")
          sharpBottomRight: (parent.touchesNext
              && (root.shellConfig.notifications.side === "right"
                || parent.nextCoversOuterCorner))
            || (parent.edgeAdjacent
              && root.touchesAnchorCorner
              && root.resolvedEdge === "bottom"
              && root.shellConfig.notifications.side === "right")
        }
      }
    }
  }
}
