pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  required property var output
  required property var theme
  property bool shown: false
  property bool framed: true
  property real requestedWidth: theme.menu.searchWidth
  property real requestedHeight: 0
  property real reveal: shown ? 1 : 0
  readonly property alias modalBody: body
  readonly property alias modalFrame: frame
  default property alias modalData: body.data

  signal outsideClicked()
  signal keyPressed(var event, bool editing)

  visible: shown || reveal > 0
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "hyprkarl-quickshell-overlay"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: shown
    ? WlrKeyboardFocus.Exclusive
    : WlrKeyboardFocus.None

  anchors.top: true
  anchors.bottom: true
  anchors.left: true
  anchors.right: true
  screen: output

  Behavior on reveal {
    NumberAnimation {
      duration: root.theme.panel.transitionDuration
      easing.type: root.shown ? Easing.OutCubic : Easing.InCubic
    }
  }

  contentItem {
    focus: root.shown
    Keys.onPressed: event => root.keyPressed(event, false)
  }

  onShownChanged: if (shown) Qt.callLater(contentItem.forceActiveFocus)

  Rectangle {
    anchors.fill: parent
    color: root.theme.menu.scrim
    opacity: root.reveal

    MouseArea {
      anchors.fill: parent
      onClicked: root.outsideClicked()
    }
  }

  Rectangle {
    id: frame

    readonly property real frameInset: root.framed
      ? root.theme.menu.outerBorderWidth + root.theme.menu.outerPadding
      : 0

    anchors.centerIn: parent
    width: root.framed
      ? Math.min(root.requestedWidth, root.width)
      : root.width
    height: root.framed
      ? Math.min(root.requestedHeight, root.height)
      : root.height
    opacity: root.reveal
    color: root.framed ? root.theme.menu.background : "transparent"
    border.color: root.theme.menu.border
    border.width: root.framed ? root.theme.menu.outerBorderWidth : 0
    radius: root.framed ? root.theme.menu.outerRadius : 0

    MouseArea {
      anchors.fill: parent
      enabled: root.framed
    }

    Rectangle {
      id: innerFrame

      anchors.fill: parent
      anchors.margins: frame.frameInset
      color: root.framed ? root.theme.menu.background : "transparent"
      border.color: root.theme.menu.border
      border.width: root.framed ? root.theme.menu.innerBorderWidth : 0
      radius: root.framed ? root.theme.menu.innerRadius : 0

      Item {
        id: body

        anchors.fill: parent
        anchors.margins: root.framed ? root.theme.menu.innerBorderWidth : 0
        clip: root.framed
      }
    }
  }
}
