import QtQml
import Quickshell.Io

// Runs one command widget's command and keeps its latest output: { text }
// for plain output, or the object a JSON command printed. A failure is
// logged and the last good output stays.
QtObject {
  id: root

  required property var config
  property var result: null

  function accept(output: string): void {
    if (config.output !== "json") {
      result = { "text": output.trim() }
      return
    }
    try {
      result = JSON.parse(output)
    } catch (error) {
      console.warn(`Command widget '${config.id}': ${error}`)
    }
  }

  property Process pollProcess: Process {
    stdout: StdioCollector { id: standardOutput }
    stderr: StdioCollector { id: standardError }

    // qmllint disable signal-handler-parameters
    onExited: exitCode => {
      if (exitCode === 0) root.accept(standardOutput.text)
      else console.warn(`Command widget '${root.config.id}' exited with ${exitCode}: ${standardError.text.trim()}`)
    }
    // qmllint enable signal-handler-parameters
  }

  property Timer timer: Timer {
    interval: root.config.interval ?? 1000
    running: root.config.mode !== "stream"
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!root.pollProcess.running) root.pollProcess.exec(["bash", "-c", root.config.command])
    }
  }

  property Process streamProcess: Process {
    command: ["bash", "-c", root.config.command]
    running: root.config.mode === "stream"

    stdout: SplitParser {
      onRead: line => root.accept(line)
    }

    stderr: SplitParser {
      onRead: line => console.warn(`Command widget '${root.config.id}': ${line}`)
    }

    // qmllint disable signal-handler-parameters
    onExited: exitCode => {
      if (exitCode !== 0) console.warn(`Command widget '${root.config.id}' stream exited with ${exitCode}`)
    }
    // qmllint enable signal-handler-parameters
  }
}
