pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../components"

ShellButton {
  id: root

  required property string widgetId
  required property var config
  required property var systemState

  property bool active: false

  contentComponent: Component {
    ToggleIndicator {
      active: root.active
      onGlyph: root.config.onIcon
      offGlyph: root.config.offIcon
      theme: root.theme
    }
  }
  tooltip: active ? "Caffeine on" : "Caffeine off"
  onPrimary: toggle

  function sync(): void {
    syncProcess.running = true
  }

  function toggle(): void {
    Quickshell.execDetached(["bash", "-c", active ? config.offCommand : config.onCommand])
    active = !active
  }

  Process {
    id: syncProcess
    command: ["bash", "-c", `${root.config.syncCommand} >/dev/null 2>&1; printf '%s' $?`]
    stdout: StdioCollector {
      onStreamFinished: root.active = Number(text.trim()) === 0
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.sync()
  }
}
