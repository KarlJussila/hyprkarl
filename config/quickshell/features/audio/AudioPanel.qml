pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pipewire
import "../../components"

Item {
  id: root

  required property var theme
  required property var config
  required property bool active

  signal externalCommandRequested(string command)

  readonly property real preferredWidth: theme.panelWidth
  readonly property var output: Pipewire.defaultAudioSink
  readonly property var input: Pipewire.defaultAudioSource
  readonly property var outputNodes: Pipewire.nodes.values.filter(node =>
    (node.type & PwNodeType.Audio) && (node.type & PwNodeType.Sink) && !(node.type & PwNodeType.Stream))
  readonly property var inputNodes: Pipewire.nodes.values.filter(node =>
    (node.type & PwNodeType.Audio) && (node.type & PwNodeType.Source) && !(node.type & PwNodeType.Stream))
  readonly property var trackedNodes: outputNodes.concat(inputNodes)
    .filter((node, index, nodes) => nodes.indexOf(node) === index)

  implicitWidth: parent?.width ?? 0
  implicitHeight: content.implicitHeight

  function nodeName(node): string {
    if (!node) return "Unavailable"
    if (node.description.length > 0) return node.description
    if (node.nickname.length > 0) return node.nickname
    return node.name
  }

  PwObjectTracker {
    objects: root.trackedNodes
  }

  PanelLayout {
    id: content

    width: parent.width
    theme: root.theme
    title: "Audio"
    subtitle: root.output ? root.nodeName(root.output) : "No output device"
    action: root.config.secondaryCommand?.length > 0
      ? () => root.externalCommandRequested(root.config.secondaryCommand)
      : null

    AudioLevel {
      width: parent.width
      theme: root.theme
      title: "Output"
      node: root.output
      active: root.active
      navigationSection: "audio"
    }

    PanelSectionLabel {
      visible: root.outputNodes.length > 1
      theme: root.theme
      text: "Output device"
    }

    Repeater {
      model: root.outputNodes.length > 1 ? root.outputNodes : []

      PanelRow {
        required property var modelData

        width: parent.width
        theme: root.theme
        navigationSection: "audio"
        icon: "󰓃"
        title: root.nodeName(modelData)
        selected: modelData === Pipewire.defaultAudioSink
        busy: modelData === Pipewire.preferredDefaultAudioSink && !selected
        action: () => Pipewire.preferredDefaultAudioSink = modelData
      }
    }

    AudioLevel {
      width: parent.width
      theme: root.theme
      title: "Microphone"
      node: root.input
      active: root.active
      navigationSection: "audio"
      showPeak: true
    }

    PanelSectionLabel {
      visible: root.inputNodes.length > 1
      theme: root.theme
      text: "Input device"
    }

    Repeater {
      model: root.inputNodes.length > 1 ? root.inputNodes : []

      PanelRow {
        required property var modelData

        width: parent.width
        theme: root.theme
        navigationSection: "audio"
        icon: "󰍬"
        title: root.nodeName(modelData)
        selected: modelData === Pipewire.defaultAudioSource
        busy: modelData === Pipewire.preferredDefaultAudioSource && !selected
        action: () => Pipewire.preferredDefaultAudioSource = modelData
      }
    }
  }
}
