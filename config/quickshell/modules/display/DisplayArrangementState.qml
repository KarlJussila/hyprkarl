pragma Singleton

import QtQuick
import Quickshell.Io
import "../../ui/modal"

QtObject {
  id: root

  readonly property string surface: "display-arrangement"
  readonly property bool active: OverlayState.activeSurface === surface
  readonly property alias outputs: outputModel
  property string selectedName: ""
  property bool loading: false
  property bool applying: false
  property bool dirty: false
  property string error: ""
  property string validationError: ""
  property var originalArrangement: ({})
  property real viewportX: 0
  property real viewportY: 0
  property real viewportWidth: 1
  property real viewportHeight: 1

  property ListModel outputModel: ListModel { id: outputModel }

  function open(output: string): void {
    outputModel.clear()
    selectedName = ""
    dirty = false
    error = ""
    if (!OverlayState.replace(surface, output, {})) return
    refresh(output)
  }

  function close(): void {
    OverlayState.close(surface)
  }

  function refresh(output: string): void {
    loading = true
    error = ""
    stateProcess.exec(["hk-display", "state", output])
  }

  function acceptState(value: string): void {
    try {
      const state = JSON.parse(value)
      const activeOutputs = state.outputs.filter(output => output.enabled)
      if (activeOutputs.length < 2) {
        throw new Error("At least two active displays are required")
      }

      outputModel.clear()
      const originals = {}
      let minimumX = activeOutputs[0].x
      let minimumY = activeOutputs[0].y
      let maximumX = activeOutputs[0].x + activeOutputs[0].logicalWidth
      let maximumY = activeOutputs[0].y + activeOutputs[0].logicalHeight
      for (const output of activeOutputs) {
        const scale = Number(output.scale)
        const baseLogicalWidth = Math.round(output.width / scale)
        const baseLogicalHeight = Math.round(output.height / scale)
        outputModel.append({
          "name": output.name,
          "description": output.description,
          "positionX": output.x,
          "positionY": output.y,
          "outputTransform": output.transform,
          "baseLogicalWidth": baseLogicalWidth,
          "baseLogicalHeight": baseLogicalHeight,
          "logicalWidth": output.logicalWidth,
          "logicalHeight": output.logicalHeight
        })
        originals[output.name] = {
          "x": output.x,
          "y": output.y,
          "transform": output.transform
        }
        minimumX = Math.min(minimumX, output.x)
        minimumY = Math.min(minimumY, output.y)
        maximumX = Math.max(maximumX, output.x + output.logicalWidth)
        maximumY = Math.max(maximumY, output.y + output.logicalHeight)
      }

      const desktopWidth = Math.max(1, maximumX - minimumX)
      const desktopHeight = Math.max(1, maximumY - minimumY)
      viewportX = minimumX - desktopWidth * 0.3
      viewportY = minimumY - desktopHeight * 0.3
      viewportWidth = desktopWidth * 1.6
      viewportHeight = desktopHeight * 1.6
      originalArrangement = originals
      selectedName = state.target
      dirty = false
      error = ""
      validationError = ""
    } catch (parseError) {
      error = parseError.message || "Display state returned invalid data"
      console.warn("Could not prepare display arrangement: " + parseError)
    }
    loading = false
  }

  function indexOf(name: string): int {
    for (let index = 0; index < outputModel.count; index++) {
      if (outputModel.get(index).name === name) return index
    }
    return -1
  }

  function select(name: string): void {
    selectedName = name
  }

  function move(name: string, x: int, y: int): void {
    const index = indexOf(name)
    if (index < 0) return
    outputModel.setProperty(index, "positionX", x)
    outputModel.setProperty(index, "positionY", y)
    updateDraftState()
  }

  function rotateClockwise(name: string): void {
    const index = indexOf(name)
    if (index < 0 || loading || applying) return
    const output = outputModel.get(index)
    const flip = output.outputTransform >= 4 ? 4 : 0
    const transform = flip + ((output.outputTransform - flip + 1) % 4)
    outputModel.setProperty(index, "outputTransform", transform)
    outputModel.setProperty(
      index,
      "logicalWidth",
      transform % 2 === 0
        ? output.baseLogicalWidth
        : output.baseLogicalHeight
    )
    outputModel.setProperty(
      index,
      "logicalHeight",
      transform % 2 === 0
        ? output.baseLogicalHeight
        : output.baseLogicalWidth
    )
    selectedName = name
    updateDraftState()
  }

  function overlaps(first: var, second: var): bool {
    return first.positionX < second.positionX + second.logicalWidth
      && first.positionX + first.logicalWidth > second.positionX
      && first.positionY < second.positionY + second.logicalHeight
      && first.positionY + first.logicalHeight > second.positionY
  }

  function updateDraftState(): void {
    dirty = false
    validationError = ""
    for (let index = 0; index < outputModel.count; index++) {
      const output = outputModel.get(index)
      const original = originalArrangement[output.name]
      if (!original
          || output.positionX !== original.x
          || output.positionY !== original.y
          || output.outputTransform !== original.transform) {
        dirty = true
      }
      for (let otherIndex = index + 1;
           otherIndex < outputModel.count;
           otherIndex++) {
        const other = outputModel.get(otherIndex)
        if (overlaps(output, other)) {
          validationError = `${output.name} overlaps ${other.name}`
          break
        }
      }
    }
  }

  function reset(): void {
    for (let index = 0; index < outputModel.count; index++) {
      const output = outputModel.get(index)
      const original = originalArrangement[output.name]
      outputModel.setProperty(index, "positionX", original.x)
      outputModel.setProperty(index, "positionY", original.y)
      outputModel.setProperty(index, "outputTransform", original.transform)
      outputModel.setProperty(
        index,
        "logicalWidth",
        original.transform % 2 === 0
          ? output.baseLogicalWidth
          : output.baseLogicalHeight
      )
      outputModel.setProperty(
        index,
        "logicalHeight",
        original.transform % 2 === 0
          ? output.baseLogicalHeight
          : output.baseLogicalWidth
      )
    }
    dirty = false
    validationError = ""
  }

  function apply(): void {
    if (!dirty || validationError.length > 0 || applying) return
    const arrangement = {}
    for (let index = 0; index < outputModel.count; index++) {
      const output = outputModel.get(index)
      arrangement[output.name] = {
        "x": output.positionX,
        "y": output.positionY,
        "transform": output.outputTransform
      }
    }
    applying = true
    error = ""
    applyProcess.exec([
      "hk-display", "arrange", JSON.stringify(arrangement)
    ])
  }

  property Process stateProcess: Process {
    stdout: StdioCollector { id: stateOutput }
    stderr: StdioCollector { id: stateError }

    // qmllint disable signal-handler-parameters
    onExited: exitCode => {
      if (exitCode === 0) {
        root.acceptState(stateOutput.text)
      } else {
        root.loading = false
        root.error = stateError.text.trim() || "Could not read display state"
      }
    }
    // qmllint enable signal-handler-parameters
  }

  property Process applyProcess: Process {
    stdout: StdioCollector {}
    stderr: StdioCollector { id: applyError }

    // qmllint disable signal-handler-parameters
    onExited: exitCode => {
      root.applying = false
      if (exitCode === 0) {
        root.close()
      } else {
        root.error = applyError.text.trim() || "Could not arrange displays"
      }
    }
    // qmllint enable signal-handler-parameters
  }
}
