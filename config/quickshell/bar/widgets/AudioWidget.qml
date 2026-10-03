pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pipewire
import "../../modules/audio"
import "../../ui/controls"
import "../../ui/indicators"

ShellButton {
  id: root

  required property string widgetId
  required property var config
  required property var systemState

  readonly property var audio: Pipewire.defaultAudioSink?.audio
  readonly property int percentage: Math.round((audio?.volume ?? 0) * 100)
  readonly property bool panelOpen: panelHost?.activeId === widgetId

  contentComponent: Component {
    Row {
      spacing: 4

      AudioIndicator {
        anchors.verticalCenter: parent.verticalCenter
        volume: root.audio?.volume ?? 0
        muted: root.audio?.muted ?? false
        indicatorColor: root.theme.palette.foreground
        inactiveWaveColor: root.theme.palette.border
      }

      Text {
        visible: root.config.showPercentage
        text: `${root.percentage}%`
        color: root.theme.palette.foreground
        font.family: root.theme.typography.monoFamily
        font.pixelSize: root.theme.typography.readoutSize
        font.weight: root.theme.typography.weight
        font.styleName: root.theme.typography.style
      }
    }
  }
  tooltip: audio?.muted ? "Muted" : `Volume: ${percentage}%`
  tooltipSuppressed: panelOpen
  onPrimary: panelHost
    ? () => panelHost.toggle(widgetId, root, panelComponent)
    : null
  secondaryCommand: config.secondaryCommand

  PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

  Component {
    id: panelComponent

    AudioPanel {
      theme: root.theme
      config: root.config
      active: root.panelOpen
      onExternalCommandRequested: command => root.launchPanelCommand(command)
    }
  }
}
