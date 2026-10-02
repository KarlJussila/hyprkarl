import QtQml
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  required property bool active

  property real cpuUsage: 0
  property real cpuTemp: 0
  property real gpuUsage: 0
  property real gpuVramUsed: 0
  property real gpuVramTotal: 0
  property real ramUsedPercent: 0
  property real ramUsed: 0
  property real ramTotal: 0
  property real swapUsed: 0
  property real swapTotal: 0
  property bool recording: false

  function update(line: string): void {
    const values = JSON.parse(line)
    cpuUsage = values.cpuUsage
    cpuTemp = values.cpuTemp
    gpuUsage = values.gpuUsage
    gpuVramUsed = values.gpuVramUsed
    gpuVramTotal = values.gpuVramTotal
    ramUsedPercent = values.ramUsedPercent
    ramUsed = values.ramUsed
    ramTotal = values.ramTotal
    swapUsed = values.swapUsed
    swapTotal = values.swapTotal
    recording = values.recording
  }

  property Process monitor: Process {
    running: false
    command: ["bash", Quickshell.shellPath("bar/read-system-state.sh")]
    stdout: SplitParser {
      onRead: line => root.update(line)
    }
    // qmllint disable signal-handler-parameters
    onExited: if (root.active) running = true
    // qmllint enable signal-handler-parameters
  }

  onActiveChanged: {
    if (active && !monitor.running) monitor.running = true
    if (!active && monitor.running) monitor.running = false
  }

  Component.onCompleted: if (active) monitor.running = true
}
