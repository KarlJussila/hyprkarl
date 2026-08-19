pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pipewire
import "../components"
import "../features/audio"

ShellButton {
  id: root

  required property string widgetId
  required property var config
  required property var systemState

  readonly property var audio: Pipewire.defaultAudioSink?.audio
  readonly property int percentage: Math.round((audio?.volume ?? 0) * 100)
  readonly property bool panelOpen: panelHost.activeId === widgetId

  contentComponent: Component {
    Row {
      spacing: 4

      AudioIndicator {
        anchors.verticalCenter: parent.verticalCenter
        volume: root.audio?.volume ?? 0
        muted: root.audio?.muted ?? false
        indicatorColor: root.theme.foreground
      }

      Text {
        visible: root.config.showPercentage
        text: `${root.percentage}%`
        color: root.theme.foreground
        font.family: root.theme.monoFontFamily
        font.pixelSize: root.theme.readoutFontSize
        font.weight: root.theme.fontWeight
        font.styleName: root.theme.fontStyle
      }
    }
  }
  tooltip: audio?.muted ? "Muted" : `Volume: ${percentage}%`
  tooltipSuppressed: panelOpen
  onPrimary: () => panelHost.toggle(widgetId, root, panelComponent)
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
