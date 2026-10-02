pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pipewire
import "../../ui/panels"

Item {
  id: root

  required property var theme
  required property string title
  required property var node
  required property bool active
  property string navigationSection: "main"
  property bool showPeak: false

  readonly property var audio: node?.audio ?? null
  readonly property string nodeName: node
    ? (node.description.length > 0 ? node.description : node.nickname.length > 0 ? node.nickname : node.name)
    : "Unavailable"

  implicitWidth: parent?.width ?? 0
  implicitHeight: content.implicitHeight

  PwNodePeakMonitor {
    id: peakMonitor
    node: root.node
    enabled: root.active && root.showPeak && root.node !== null
  }

  Column {
    id: content

    width: parent.width
    spacing: 4

    PanelRow {
      width: parent.width
      theme: root.theme
      navigationSection: root.navigationSection
      icon: root.audio?.muted ? "󰝟" : root.showPeak ? "󰍬" : "󰕾"
      title: root.title
      detail: root.audio ? root.nodeName : "unavailable"
      switchVisible: root.audio !== null
      switchActive: root.audio !== null && !root.audio.muted
      enabled: root.audio !== null
      action: root.audio ? () => root.audio.muted = !root.audio.muted : null
    }

    PanelSlider {
      width: parent.width
      theme: root.theme
      navigationSection: root.navigationSection
      enabled: root.audio !== null
      value: root.audio?.volume ?? 0
      onEdited: value => root.audio.volume = value
    }

    Rectangle {
      visible: root.showPeak && root.audio !== null
      width: parent.width
      height: visible ? 3 : 0
      radius: 2
      color: root.theme.panelBorder

      Rectangle {
        width: parent.width * Math.max(0, Math.min(1, peakMonitor.peak))
        height: parent.height
        radius: parent.radius
        color: root.theme.panelAccent
      }
    }
  }
}
