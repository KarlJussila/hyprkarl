pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pipewire
import "../../components"

Item {
  id: root

  required property var theme
  required property string title
  required property var node
  required property bool active
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
      icon: root.audio?.muted ? "󰝟" : root.showPeak ? "󰍬" : "󰕾"
      title: root.title
      detail: root.audio ? (root.audio.muted ? "muted" : root.nodeName) : "unavailable"
      selected: root.audio?.muted ?? false
      enabled: root.audio !== null
      action: root.audio ? () => root.audio.muted = !root.audio.muted : null
    }

    AudioSlider {
      width: parent.width
      theme: root.theme
      enabled: root.audio !== null
      value: root.audio?.volume ?? 0
      onEdited: value => root.audio.volume = value
    }

    Rectangle {
      visible: root.showPeak && root.audio !== null
      width: parent.width
      height: visible ? 3 : 0
      radius: 2
      color: root.theme.border

      Rectangle {
        width: parent.width * Math.max(0, Math.min(1, peakMonitor.peak))
        height: parent.height
        radius: parent.radius
        color: root.theme.accent
      }
    }
  }
}
