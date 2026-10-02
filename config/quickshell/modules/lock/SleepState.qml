import QtQml
import Quickshell.Io

QtObject {
  id: root
  property bool ready: false
  property bool preparing: false

  property Process monitor: Process {
    command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1",
      "--object-path", "/org/freedesktop/login1"]
    running: true
    stdout: SplitParser {
      onRead: line => {
        const sleep = line.match(/Manager\.PrepareForSleep \((true|false),\)/)
        if (sleep) {
          root.preparing = sleep[1] === "true"
          root.ready = true
        } else if (line.startsWith("The name org.freedesktop.login1 is owned by ")) {
          root.initialState.running = true
        }
      }
    }
  }

  // Query only after subscribing, so a locker started by hypridle's
  // before_sleep_cmd cannot miss the resume signal.
  property Process initialState: Process {
    command: ["gdbus", "call", "--system", "--dest", "org.freedesktop.login1",
      "--object-path", "/org/freedesktop/login1",
      "--method", "org.freedesktop.DBus.Properties.Get",
      "org.freedesktop.login1.Manager", "PreparingForSleep"]
    stdout: StdioCollector {
      onStreamFinished: {
        // A signal that arrived while this query ran is newer.
        if (!root.ready) {
          root.preparing = text.includes("<true>")
          root.ready = true
        }
      }
    }
  }
}
