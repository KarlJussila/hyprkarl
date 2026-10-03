pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../../ui/controls"

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
      appearance: root.config.switch ?? ({})
      theme: root.theme
    }
  }
  tooltip: config.tooltip ?? ""
  onPrimary: toggle

  function sync(): void {
    syncProcess.running = true
  }

  function toggle(): void {
    Quickshell.execDetached(["uwsm-app", "--", "bash", "-c", active ? config.offCommand : config.onCommand])
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
