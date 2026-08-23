pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  required property var output
  required property var theme
  property bool shown: false
  property real requestedWidth: theme.menuSearchWidth
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
      duration: root.theme.panelTransitionDuration
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
    color: root.theme.menuScrim
    opacity: root.reveal

    MouseArea {
      anchors.fill: parent
      onClicked: root.outsideClicked()
    }
  }

  Rectangle {
    id: frame

    readonly property real frameInset: root.theme.menuOuterBorderWidth
      + root.theme.menuOuterPadding

    anchors.centerIn: parent
    width: Math.min(root.requestedWidth, root.width)
    height: Math.min(root.requestedHeight, root.height)
    opacity: root.reveal
    color: root.theme.menuBackground
    border.color: root.theme.menuBorder
    border.width: root.theme.menuOuterBorderWidth
    radius: root.theme.menuOuterRadius

    MouseArea { anchors.fill: parent }

    Rectangle {
      id: innerFrame

      anchors.fill: parent
      anchors.margins: frame.frameInset
      color: root.theme.menuBackground
      border.color: root.theme.menuBorder
      border.width: root.theme.menuInnerBorderWidth
      radius: root.theme.menuInnerRadius

      Item {
        id: body

        anchors.fill: parent
        anchors.margins: root.theme.menuInnerBorderWidth
        clip: true
      }
    }
  }
}
