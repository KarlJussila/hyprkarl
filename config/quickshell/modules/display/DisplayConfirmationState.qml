pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../ui/modal"

QtObject {
  id: root

  readonly property string surface: "display-confirmation"
  readonly property bool active: OverlayState.activeSurface === surface
  readonly property int remainingSeconds: Math.max(
    0, Math.ceil((deadline - currentTime) / 1000))
  readonly property real remainingFraction: Math.max(
    0, Math.min(1, (deadline - currentTime) / 10000))
  property bool previewing: false
  property bool resolving: false
  property string token: ""
  property double deadline: 0
  property string panelOutput: ""
  property string source: ""
  property string error: ""
  property double currentTime: Date.now()

  signal trialStarted(string source)
  signal trialFailed(string source, string message)

  function preview(layout: var, output: string, requestSource: string): void {
    if (previewing || resolving || token.length > 0) return
    previewing = true
    panelOutput = output
    source = requestSource
    error = ""
    previewProcess.exec([
      "hk-display", "preview", JSON.stringify(layout)
    ])
  }

  function confirmationOutput(): string {
    for (const output of Quickshell.screens) {
      if (output.name === panelOutput) return output.name
    }
    return Quickshell.screens[0]?.name ?? ""
  }

  function showConfirmation(): void {
    const output = confirmationOutput()
    if (output.length === 0) {
      revert()
      return
    }
    OverlayState.replace(surface, output, {})
    currentTime = Date.now()
    countdown.restart()
    trialStarted(source)
  }

  function confirm(): void {
    if (token.length === 0 || resolving) return
    resolving = true
    countdown.stop()
    confirmProcess.exec(["hk-display", "confirm", token])
  }

  function revert(): void {
    if (token.length === 0 || resolving) return
    resolving = true
    countdown.stop()
    revertProcess.exec(["hk-display", "revert", token])
  }

  function finish(): void {
    token = ""
    deadline = 0
    panelOutput = ""
    source = ""
    resolving = false
    if (active) OverlayState.close(surface)
  }

  onActiveChanged: {
    if (!active && token.length > 0 && !resolving) revert()
  }

  property Timer showDelay: Timer {
    interval: 200
    onTriggered: root.showConfirmation()
  }

  property Timer countdown: Timer {
    interval: 100
    repeat: true
    onTriggered: {
      root.currentTime = Date.now()
      if (root.currentTime >= root.deadline) root.revert()
    }
  }

  property Process previewProcess: Process {
    stdout: StdioCollector { id: previewOutput }
    stderr: StdioCollector { id: previewError }

    // qmllint disable signal-handler-parameters
    onExited: exitCode => {
      root.previewing = false
      if (exitCode !== 0) {
        const message = previewError.text.trim()
          || "Could not apply the display changes"
        root.error = message
        root.trialFailed(root.source, message)
        root.source = ""
        return
      }
      const transaction = JSON.parse(previewOutput.text)
      root.token = transaction.token
      root.deadline = transaction.deadline
      root.showDelay.restart()
    }
    // qmllint enable signal-handler-parameters
  }

  property Process confirmProcess: Process {
    stderr: StdioCollector { id: confirmError }

    // qmllint disable signal-handler-parameters
    onExited: exitCode => {
      if (exitCode !== 0) {
        root.error = confirmError.text.trim()
          || "Could not keep the display changes"
      }
      root.finish()
    }
    // qmllint enable signal-handler-parameters
  }

  property Process revertProcess: Process {
    stderr: StdioCollector { id: revertError }

    // qmllint disable signal-handler-parameters
    onExited: exitCode => {
      if (exitCode !== 0) {
        root.error = revertError.text.trim()
          || "Could not restore the previous display layout"
        console.warn(root.error)
      }
      root.finish()
    }
    // qmllint enable signal-handler-parameters
  }
}
