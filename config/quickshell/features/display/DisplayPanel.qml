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
  readonly property bool brightnessBusy: brightnessPreview >= 0
    || brightnessProcess.running
  property var displayState: ({
    "target": outputName,
    "outputs": [],
    "scale": 1,
    "scalePresets": [],
    "brightness": { "available": false, "percent": 0 }
  })
  property int brightnessPreview: -1
  property int brightnessDesired: -1
  property int brightnessInFlight: -1
  property int brightnessRevision: 0
  property int stateBrightnessRevision: 0
  property string currentAction: ""
  property string actionTarget: ""
  property string error: ""

  implicitWidth: parent?.width ?? 0
  implicitHeight: content.implicitHeight

  function refresh(): void {
    if (stateProcess.running || brightnessBusy) return
    stateBrightnessRevision = brightnessRevision
    stateProcess.exec(["hk-display", "state", outputName])
  }

  function acceptState(value: string): void {
    try {
      const nextState = JSON.parse(value)
      if (stateBrightnessRevision !== brightnessRevision) {
        nextState.brightness = displayState.brightness
      }
      displayState = nextState
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

  function commitBrightness(percent: int): void {
    const nextState = Object.assign({}, displayState)
    nextState.brightness = Object.assign({}, displayState.brightness, {
      "percent": percent
    })
    displayState = nextState
  }

  function startBrightnessWrite(): void {
    brightnessInFlight = brightnessDesired
    brightnessProcess.exec([
      "hk-display", "brightness", displayState.target,
      String(brightnessInFlight)
    ])
  }

  function queueBrightness(value: real): void {
    const percent = Math.max(1, Math.round(value * 100))
    brightnessPreview = percent
    if (brightnessDesired === percent) return

    brightnessDesired = percent
    brightnessRevision++
    error = ""
    if (!brightnessProcess.running) startBrightnessWrite()
  }

  onActiveChanged: if (active) refresh()

  Timer {
    interval: 3000
    running: root.active
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
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
      settleRefresh.restart()
    }
    // qmllint enable signal-handler-parameters
  }

  Process {
    id: brightnessProcess

    stderr: StdioCollector { id: brightnessError }

    // qmllint disable signal-handler-parameters
    onExited: exitCode => {
      if (exitCode !== 0) {
        root.error = brightnessError.text.trim() || "Brightness change failed"
        root.brightnessPreview = -1
        root.brightnessDesired = -1
        root.brightnessInFlight = -1
        settleRefresh.restart()
        return
      }

      root.commitBrightness(root.brightnessInFlight)
      if (root.brightnessDesired !== root.brightnessInFlight) {
        root.startBrightnessWrite()
      } else {
        root.brightnessPreview = -1
        root.brightnessDesired = -1
        root.brightnessInFlight = -1
      }
    }
    // qmllint enable signal-handler-parameters
  }

  PanelLayout {
    id: content

    width: parent.width
    theme: root.theme
    title: "Display"
    subtitle: root.target.description?.length > 0
      ? `${root.displayState.target} · ${root.target.description}`
      : root.displayState.target

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
      onEdited: value => root.queueBrightness(value)
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
          id: scaleOption

          required property real modelData

          readonly property bool selected: Math.abs(
            modelData - root.displayState.scale) < 0.01
          width: scales.itemWidth
          height: 32
          activeFocusOnTab: true

          Rectangle {
            anchors.fill: parent
            color: root.theme.panelBackground
            border.color: parent.activeFocus || scaleMouse.containsMouse || parent.selected
              ? root.theme.panelAccent
              : "transparent"
            border.width: parent.activeFocus || scaleMouse.containsMouse || parent.selected
              ? root.theme.panelSelectionBorderWidth
              : 0
            radius: root.theme.panelEntryRadius

            Rectangle {
              anchors.fill: parent
              color: root.theme.panelAccent
              opacity: scaleOption.activeFocus
                || scaleMouse.containsMouse
                || scaleOption.selected
                ? root.theme.panelSelectionAccentOpacity
                : 0
              radius: parent.radius
            }
          }

          Text {
            anchors.centerIn: parent
            text: `${Number(parent.modelData.toFixed(2))}×`
            color: parent.selected ? root.theme.panelAccent : root.theme.panelForeground
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
        detail: modelData.name === root.displayState.target ? "this display" : ""
        switchVisible: true
        switchActive: modelData.enabled
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
      font.family: root.theme.panelFont
      font.pixelSize: root.theme.readoutFontSize
    }
  }
}
