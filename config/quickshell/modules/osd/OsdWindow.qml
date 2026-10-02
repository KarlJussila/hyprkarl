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
  implicitWidth: osdState.media ? theme.osdMediaWidth : theme.osdWidth
  implicitHeight: surface.implicitHeight
  mask: Region {}

  anchors.top: shellConfig.osdEdge === "top"
  anchors.bottom: shellConfig.osdEdge === "bottom"
  margins.top: shellConfig.osdEdge === "top" ? shellConfig.osdMargin : 0
  margins.bottom: shellConfig.osdEdge === "bottom" ? shellConfig.osdMargin : 0

  WlrLayershell.namespace: "hyprkarl-quickshell-osd"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  Behavior on reveal {
    NumberAnimation {
      duration: root.theme.osdTransitionDuration
      easing.type: root.active ? Easing.OutCubic : Easing.InCubic
    }
  }

  Rectangle {
    id: surface

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: content.implicitHeight + root.theme.osdPadding * 2
    height: implicitHeight
    opacity: root.reveal
    y: root.shellConfig.osdEdge === "top"
      ? (root.reveal - 1) * root.theme.osdSpacing
      : (1 - root.reveal) * root.theme.osdSpacing
    color: root.theme.popupSurface
    border.color: root.theme.border
    border.width: root.theme.borderWidth
    radius: root.theme.osdRadius

    ColumnLayout {
      id: content

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: root.theme.osdPadding
      anchors.rightMargin: root.theme.osdPadding
      spacing: root.theme.osdSpacing

      RowLayout {
        Layout.fillWidth: true
        spacing: root.theme.osdSpacing

        Item {
          implicitWidth: root.theme.osdIconSize
          implicitHeight: root.theme.osdIconSize

          AudioIndicator {
            visible: root.osdState.kind === "volume"
              || root.osdState.kind === "output"
            anchors.centerIn: parent
            volume: root.osdState.value / 100
            muted: root.osdState.muted
            indicatorColor: root.theme.foreground
            inactiveWaveColor: root.theme.border
          }

          Text {
            visible: root.osdState.kind !== "volume"
              && root.osdState.kind !== "output"
            anchors.centerIn: parent
            text: root.osdState.glyph
            color: root.theme.foreground
            font.family: root.theme.uiFontFamily
            font.pixelSize: root.theme.osdIconSize
            font.weight: root.theme.fontWeight
            font.styleName: root.theme.fontStyle
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 0

          Text {
            Layout.fillWidth: true
            text: root.osdState.title
            color: root.theme.foreground
            font.family: root.theme.uiFontFamily
            font.pixelSize: root.theme.bodyFontSize
            font.weight: root.theme.fontWeight
            font.styleName: root.theme.fontStyle
            elide: Text.ElideRight
          }

          Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.osdState.detail
            color: root.theme.muted
            font.family: root.theme.uiFontFamily
            font.pixelSize: root.theme.bodyFontSize
            font.weight: root.theme.fontWeight
            font.styleName: root.theme.fontStyle
            elide: Text.ElideRight
          }
        }

        Text {
          visible: root.osdState.showValue
          text: root.osdState.value + "%"
          color: root.theme.foreground
          font.family: root.theme.monoFontFamily
          font.pixelSize: root.theme.readoutFontSize
          font.weight: root.theme.fontWeight
          font.styleName: root.theme.fontStyle
        }
      }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: root.theme.osdProgressHeight
        visible: root.osdState.showProgress
        color: root.theme.border
        radius: height / 2

        Rectangle {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: parent.width * root.osdState.value / 100
          color: root.theme.accent
          radius: parent.radius
        }
      }
    }
  }
}
