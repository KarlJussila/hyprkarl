pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../ui/indicators"

PanelWindow {
  id: root

  required property var output
  required property var osdState
  required property var shellConfig
  required property var theme

  readonly property bool active: osdState.requested
    && output.name === osdState.screenName
  property real reveal: active ? 1 : 0

  visible: active || reveal > 0
  screen: output
  color: "transparent"
  focusable: false
  aboveWindows: true
  exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0
  implicitWidth: osdState.media ? theme.osd.mediaWidth : theme.osd.width
  implicitHeight: surface.implicitHeight
  mask: Region {}

  anchors.top: shellConfig.osd.edge === "top"
  anchors.bottom: shellConfig.osd.edge === "bottom"
  margins.top: shellConfig.osd.edge === "top" ? shellConfig.osd.margin : 0
  margins.bottom: shellConfig.osd.edge === "bottom" ? shellConfig.osd.margin : 0

  WlrLayershell.namespace: "hyprkarl-quickshell-osd"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  Behavior on reveal {
    NumberAnimation {
      duration: root.theme.osd.transitionDuration
      easing.type: root.active ? Easing.OutCubic : Easing.InCubic
    }
  }

  Rectangle {
    id: surface

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: content.implicitHeight + root.theme.osd.padding * 2
    height: implicitHeight
    opacity: root.reveal
    y: root.shellConfig.osd.edge === "top"
      ? (root.reveal - 1) * root.theme.osd.spacing
      : (1 - root.reveal) * root.theme.osd.spacing
    color: root.theme.surfaces.popup
    border.color: root.theme.palette.border
    border.width: root.theme.metrics.borderWidth
    radius: root.theme.osd.radius

    ColumnLayout {
      id: content

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: root.theme.osd.padding
      anchors.rightMargin: root.theme.osd.padding
      spacing: root.theme.osd.spacing

      RowLayout {
        Layout.fillWidth: true
        spacing: root.theme.osd.spacing

        Item {
          implicitWidth: root.theme.osd.iconSize
          implicitHeight: root.theme.osd.iconSize

          AudioIndicator {
            visible: root.osdState.kind === "volume"
              || root.osdState.kind === "output"
            anchors.centerIn: parent
            volume: root.osdState.value / 100
            muted: root.osdState.muted
            indicatorColor: root.theme.palette.foreground
            inactiveWaveColor: root.theme.palette.border
          }

          Text {
            visible: root.osdState.kind !== "volume"
              && root.osdState.kind !== "output"
            anchors.centerIn: parent
            text: root.osdState.glyph
            color: root.theme.palette.foreground
            font.family: root.theme.typography.uiFamily
            font.pixelSize: root.theme.osd.iconSize
            font.weight: root.theme.typography.weight
            font.styleName: root.theme.typography.style
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 0

          Text {
            Layout.fillWidth: true
            text: root.osdState.title
            color: root.theme.palette.foreground
            font.family: root.theme.typography.uiFamily
            font.pixelSize: root.theme.typography.bodySize
            font.weight: root.theme.typography.weight
            font.styleName: root.theme.typography.style
            elide: Text.ElideRight
          }

          Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.osdState.detail
            color: root.theme.palette.muted
            font.family: root.theme.typography.uiFamily
            font.pixelSize: root.theme.typography.bodySize
            font.weight: root.theme.typography.weight
            font.styleName: root.theme.typography.style
            elide: Text.ElideRight
          }
        }

        Text {
          visible: root.osdState.showValue
          text: root.osdState.value + "%"
          color: root.theme.palette.foreground
          font.family: root.theme.typography.monoFamily
          font.pixelSize: root.theme.typography.readoutSize
          font.weight: root.theme.typography.weight
          font.styleName: root.theme.typography.style
        }
      }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: root.theme.osd.progressHeight
        visible: root.osdState.showProgress
        color: root.theme.palette.border
        radius: height / 2

        Rectangle {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: parent.width * root.osdState.value / 100
          color: root.theme.palette.accent
          radius: parent.radius
        }
      }
    }
  }
}
