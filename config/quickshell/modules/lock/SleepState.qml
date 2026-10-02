import QtQml
import Quickshell.Io

QtObject {
  id: root
  property bool ready: false
  property bool preparing: false
  signal resumed()

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
          if (!root.preparing) root.resumed()
        } else if (line.startsWith("The name org.freedesktop.login1 is owned by ")) {
          root.initialState.running = true
        }
      }
    }
  }

  // Subscribe first so a locker launched during sleep preparation cannot miss resume.
  property Process initialState: Process {
    command: ["gdbus", "call", "--system", "--dest", "org.freedesktop.login1",
      "--object-path", "/org/freedesktop/login1",
      "--method", "org.freedesktop.DBus.Properties.Get",
      "org.freedesktop.login1.Manager", "PreparingForSleep"]
    stdout: StdioCollector {
      onStreamFinished: {
        // A newer signal owns the state if it arrived while this query was running.
        if (!root.ready) {
          root.preparing = text.includes("<true>")
          root.ready = true
        }
      }
    }
  }
}
