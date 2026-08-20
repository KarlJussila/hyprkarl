pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "../../components"

Item {
  id: root

  required property var theme
  required property bool active
  required property string outputName

  readonly property real preferredWidth: theme.panelWidth
  readonly property var target: displayState.outputs.find(
    output => output.name === displayState.target) ?? ({})
  readonly property int activeOutputCount: displayState.outputs.filter(
    output => output.enabled).length
  readonly property int currentBrightness: brightnessPreview >= 0
    ? brightnessPreview
    : displayState.brightness.percent
  property var displayState: ({
    "target": outputName,
    "outputs": [],
    "scale": 1,
    "scalePresets": [],
    "brightness": { "available": false, "percent": 0 }
  })
  property int brightnessPreview: -1
  property bool brightnessPending: false
  property string currentAction: ""
  property string actionTarget: ""
  property string error: ""

  implicitWidth: parent?.width ?? 0
  implicitHeight: content.implicitHeight

  function refresh(): void {
    if (!stateProcess.running) {
      stateProcess.exec(["hk-display", "state", outputName])
    }
  }

  function acceptState(value: string): void {
    try {
      displayState = JSON.parse(value)
      error = ""
    } catch (parseError) {
      error = "Display state returned invalid data"
      console.warn(error + ": " + parseError)
    }
  }

  function runAction(action: string, output: string, argument: string): void {
    if (actionProcess.running) return
    currentAction = action
    actionTarget = output
    error = ""
    const command = ["hk-display", action, output]
    if (argument.length > 0) command.push(argument)
    actionProcess.exec(command)
  }

  function applyBrightness(): void {
    if (actionProcess.running) {
      brightnessPending = true
      return
    }
    brightnessPending = false
    runAction("brightness", displayState.target, String(currentBrightness))
  }

  onActiveChanged: {
    if (active) refresh()
    else brightnessDebounce.stop()
  }

  Timer {
    interval: 3000
    running: root.active
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: brightnessDebounce

    interval: 160
    onTriggered: root.applyBrightness()
  }

  Timer {
    id: settleRefresh

    interval: 250
    onTriggered: root.refresh()
  }

  Process {
    id: stateProcess

    stdout: StdioCollector { id: stateOutput }
    stderr: StdioCollector { id: stateError }

    // qmllint disable signal-handler-parameters
    onExited: exitCode => {
      if (exitCode === 0) {
        root.acceptState(stateOutput.text)
      } else {
        root.error = stateError.text.trim() || "Could not read display state"
      }
    }
    // qmllint enable signal-handler-parameters
  }

  Process {
    id: actionProcess

    stdout: StdioCollector {}
    stderr: StdioCollector { id: actionError }

    // qmllint disable signal-handler-parameters
    onExited: exitCode => {
      if (exitCode !== 0) {
        root.error = actionError.text.trim() || "Display change failed"
      }
      root.currentAction = ""
      root.actionTarget = ""
      if (root.brightnessPending) {
        root.applyBrightness()
      } else {
        root.brightnessPreview = -1
        settleRefresh.restart()
      }
    }
    // qmllint enable signal-handler-parameters
  }

  Column {
    id: content

    width: parent.width
    spacing: root.theme.panelSpacing

    PanelHeader {
      width: parent.width
      theme: root.theme
      title: "Display"
      subtitle: root.target.description?.length > 0
        ? `${root.displayState.target} · ${root.target.description}`
        : root.displayState.target
    }

    PanelSectionLabel {
      visible: root.displayState.brightness.available
      theme: root.theme
      text: "Brightness"
    }

    PanelSlider {
      visible: root.displayState.brightness.available
      width: parent.width
      theme: root.theme
      value: root.currentBrightness / 100
      stepSize: 0.05
      onEdited: value => {
        root.brightnessPreview = Math.max(1, Math.round(value * 100))
        brightnessDebounce.restart()
      }
    }

    PanelSectionLabel {
      theme: root.theme
      text: "Scale"
    }

    Row {
      id: scales

      width: parent.width
      spacing: 4
      readonly property real itemWidth: root.displayState.scalePresets.length > 0
        ? (width - spacing * (root.displayState.scalePresets.length - 1))
          / root.displayState.scalePresets.length
        : 0

      Repeater {
        model: root.displayState.scalePresets

        Item {
          required property real modelData

          readonly property bool selected: Math.abs(
            modelData - root.displayState.scale) < 0.01
          width: scales.itemWidth
          height: 32
          activeFocusOnTab: true

          Rectangle {
            anchors.fill: parent
            color: root.theme.accent
            opacity: parent.activeFocus ? 0.30
              : scaleMouse.containsMouse ? 0.22
              : parent.selected ? 0.14 : 0
            border.color: parent.selected ? root.theme.accent : root.theme.border
            border.width: root.theme.borderWidth
            radius: root.theme.controlRadius
          }

          Text {
            anchors.centerIn: parent
            text: `${Number(parent.modelData.toFixed(2))}×`
            color: parent.selected ? root.theme.accent : root.theme.foreground
            font.family: root.theme.monoFontFamily
            font.pixelSize: root.theme.readoutFontSize
          }

          MouseArea {
            id: scaleMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.runAction(
              "scale", root.displayState.target, String(parent.modelData))
          }

          Keys.onPressed: event => {
            if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space) return
            root.runAction("scale", root.displayState.target, String(modelData))
            event.accepted = true
          }
        }
      }
    }

    PanelSectionLabel {
      visible: root.displayState.outputs.length > 1
      theme: root.theme
      text: "Displays"
    }

    Repeater {
      model: root.displayState.outputs.length > 1 ? root.displayState.outputs : []

      PanelRow {
        required property var modelData

        readonly property bool isOnlyActive: modelData.enabled
          && root.activeOutputCount === 1
        width: parent.width
        theme: root.theme
        icon: modelData.name.match(/^(eDP|LVDS|DSI)-/) ? "󰌢" : "󰍹"
        title: modelData.description || modelData.name
        detail: modelData.enabled
          ? (modelData.name === root.displayState.target ? "this display" : "on")
          : "off"
        selected: modelData.enabled
        busy: root.currentAction === "toggle" && root.actionTarget === modelData.name
        enabled: !isOnlyActive && root.currentAction.length === 0
        action: enabled
          ? () => root.runAction("toggle", modelData.name, "")
          : null
      }
    }

    Text {
      visible: root.error.length > 0
      width: parent.width
      text: root.error
      color: root.theme.urgent
      wrapMode: Text.Wrap
      font.family: root.theme.uiFontFamily
      font.pixelSize: root.theme.readoutFontSize
    }
  }
}
