import QtQml
import Quickshell.Io

QtObject {
  id: root

  required property var config
  readonly property string mode: config.mode ?? "poll"
  property var result: ({
    "ready": false,
    "visible": false,
    "text": "",
    "icon": "",
    "tooltip": "",
    "state": "normal"
  })

  function defaultResult(): var {
    return {
      "ready": true,
      "visible": true,
      "text": "",
      "icon": config.icon ?? "",
      "tooltip": config.tooltip ?? "",
      "state": config.state ?? "normal"
    }
  }

  function requireString(value, field): void {
    if (value !== undefined && typeof value !== "string") {
      throw new Error("'" + field + "' must be a string")
    }
  }

  function parseJson(output): var {
    const value = JSON.parse(output)
    if (value === null || typeof value !== "object" || Array.isArray(value)) {
      throw new Error("output must be a JSON object")
    }

    const allowed = ["text", "icon", "tooltip", "state", "visible"]
    for (const field of Object.keys(value)) {
      if (allowed.indexOf(field) === -1) {
        throw new Error("unknown field '" + field + "'")
      }
    }

    requireString(value.text, "text")
    requireString(value.icon, "icon")
    requireString(value.tooltip, "tooltip")
    if (value.visible !== undefined && typeof value.visible !== "boolean") {
      throw new Error("'visible' must be a boolean")
    }
    if (value.state !== undefined
        && ["normal", "muted", "accent", "warning", "urgent"]
          .indexOf(value.state) === -1) {
      throw new Error("'state' has an unknown semantic value")
    }

    const next = defaultResult()
    for (const field of allowed) {
      if (value[field] !== undefined) next[field] = value[field]
    }
    return next
  }

  function accept(output): void {
    try {
      if ((config.output ?? "text") === "json") {
        result = parseJson(output)
      } else {
        const next = defaultResult()
        next.text = output.trim()
        result = next
      }
    } catch (error) {
      console.warn("Command widget '" + config.id
        + "' rejected its output: " + error)
    }
  }

  function poll(): void {
    if (!pollProcess.running) {
      pollProcess.exec(["bash", "-c", config.command])
    }
  }

  property Process pollProcess: Process {
    stdout: StdioCollector { id: standardOutput }
    stderr: StdioCollector { id: standardError }

    // qmllint disable signal-handler-parameters
    onExited: exitCode => {
      if (exitCode === 0) {
        root.accept(standardOutput.text)
        return
      }

      const detail = standardError.text.trim()
      console.warn("Command widget '" + root.config.id + "' exited with "
        + exitCode + (detail.length > 0 ? ": " + detail : ""))
    }
    // qmllint enable signal-handler-parameters
  }

  property Timer timer: Timer {
    interval: root.config.interval ?? 1000
    running: root.mode === "poll"
    repeat: true
    triggeredOnStart: true
    onTriggered: root.poll()
  }

  property Process streamProcess: Process {
    command: ["bash", "-c", root.config.command]

    stdout: SplitParser {
      onRead: line => root.accept(line)
    }

    stderr: SplitParser {
      onRead: line => console.warn("Command widget '" + root.config.id
        + "' stderr: " + line)
    }

    // qmllint disable signal-handler-parameters
    onExited: exitCode => {
      if (exitCode !== 0) {
        console.warn("Command widget '" + root.config.id
          + "' stream exited with " + exitCode)
      }
    }
    // qmllint enable signal-handler-parameters
  }

  Component.onCompleted: {
    if (mode === "stream") streamProcess.running = true
  }
}
