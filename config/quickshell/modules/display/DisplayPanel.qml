pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "../../ui/panels"

Item {
  id: root

  required property var theme
  required property bool active
  required property string outputName

  signal arrangeRequested()
  signal trialRequested(var layout, string panelOutput)
  signal trialStarted()

  readonly property real preferredWidth: theme.panel.width
  readonly property var target: displayState.outputs.find(
    output => output.name === displayState.target) ?? ({})
  readonly property var selectedOutput: displayState.outputs.find(
    output => output.name === selectedName) ?? ({})
  readonly property var selectedModes: selectedOutput.modes ?? []
  readonly property var draftModeEntry: selectedModes.find(
    mode => mode.value === draftMode) ?? null
  readonly property string draftResolution: draftMode === "preferred"
    ? "preferred"
    : draftModeEntry
      ? modeResolution(draftModeEntry)
      : draftMode.split("@")[0]
  readonly property real draftRefreshRate: draftModeEntry
    ? draftModeEntry.refreshRate
    : Number(draftMode.split("@")[1] ?? 0)
  readonly property var resolutionOptions: buildResolutionOptions()
  readonly property var refreshOptions: selectedModes.filter(
    mode => modeResolution(mode) === draftResolution)
  readonly property int activeOutputCount: displayState.outputs.filter(
    output => output.enabled).length
  readonly property int currentBrightness: brightnessPreview >= 0
    ? brightnessPreview
    : displayState.brightness.percent
  readonly property bool brightnessBusy: brightnessPreview >= 0
    || brightnessProcess.running
  readonly property bool draftDirty: selectedName.length > 0 && (
    draftEnabled !== selectedOutput.enabled
    || draftMode !== selectedOutput.mode
    || draftScale !== selectedOutput.scale
  )
  property string page: "overview"
  property string selectedName: ""
  property bool draftEnabled: true
  property string draftMode: "preferred"
  property var draftScale: "auto"
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
  property string error: ""

  implicitWidth: parent?.width ?? 0
  implicitHeight: content.implicitHeight

  function refresh(): void {
    if (stateProcess.running || brightnessBusy || page !== "overview") return
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

  function openDetails(name: string): void {
    const output = displayState.outputs.find(item => item.name === name)
    if (!output) return
    selectedName = name
    draftEnabled = output.enabled
    draftMode = output.mode
    draftScale = output.scale
    error = ""
    page = "detail"
  }

  function showOverview(): void {
    page = "overview"
    selectedName = ""
    error = ""
    refresh()
  }

  function showDetails(): void {
    page = "detail"
    error = ""
  }

  function goBack(): void {
    if (page === "detail") showOverview()
    else showDetails()
  }

  function setEnabled(value: bool): void {
    if (!value && selectedOutput.enabled && activeOutputCount === 1) {
      error = "The last active display cannot be disabled"
      return
    }
    draftEnabled = value
    error = ""
  }

  function buildLayout(): var {
    const outputs = {}
    for (const output of displayState.outputs) {
      outputs[output.name] = output.name === selectedName ? {
        "enabled": draftEnabled,
        "mode": draftMode,
        "position": output.position,
        "scale": draftScale,
        "transform": output.transform
      } : {
        "enabled": output.enabled,
        "mode": output.mode,
        "position": output.position,
        "scale": output.scale,
        "transform": output.transform
      }
    }
    return { "version": 1, "outputs": outputs }
  }

  function applyDraft(): void {
    if (!draftDirty || DisplayConfirmationState.previewing) return
    error = ""
    trialRequested(buildLayout(), outputName)
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

  function outputDetail(output: var): string {
    if (!output.enabled) return "off"
    const refresh = Number(output.refreshRate.toFixed(1))
    return `${output.width}×${output.height} · ${refresh} Hz`
  }

  function scaleSelected(value: var): bool {
    if (value === "auto" || draftScale === "auto") return value === draftScale
    return Math.abs(Number(value) - Number(draftScale)) < 0.01
  }

  function modeResolution(mode: var): string {
    return `${mode.width}x${mode.height}`
  }

  function buildResolutionOptions(): var {
    const options = []
    const seen = new Set()
    for (const mode of selectedModes) {
      const value = modeResolution(mode)
      if (seen.has(value)) continue
      seen.add(value)
      options.push({
        "value": value,
        "width": mode.width,
        "height": mode.height
      })
    }
    return options
  }

  function selectResolution(value: string): void {
    if (value === "preferred") {
      draftMode = "preferred"
      showDetails()
      return
    }

    const modes = selectedModes.filter(
      mode => modeResolution(mode) === value)
    const matchingRefresh = modes.find(mode =>
      Math.abs(mode.refreshRate - draftRefreshRate) < 0.001)
    draftMode = (matchingRefresh ?? modes[0]).value
    showDetails()
  }

  function selectRefresh(value: string): void {
    draftMode = value
    showDetails()
  }

  function resolutionDetail(): string {
    if (draftResolution === "preferred") return "Preferred"
    return draftResolution.replace("x", " × ")
  }

  function refreshDetail(): string {
    if (draftResolution === "preferred") return "Automatic"
    return `${Number(draftRefreshRate.toFixed(3))} Hz`
  }

  onActiveChanged: {
    if (active) {
      page = "overview"
      selectedName = ""
      refresh()
    }
  }

  Timer {
    interval: 3000
    running: root.active && root.page === "overview"
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

  Connections {
    target: DisplayConfirmationState

    function onTrialStarted(source: string): void {
      if (source === "display-panel") root.trialStarted()
    }

    function onTrialFailed(source: string, message: string): void {
      if (source === "display-panel") root.error = message
    }
  }

  PanelLayout {
    id: content

    width: parent.width
    theme: root.theme
    title: root.page === "overview"
      ? "Displays"
      : root.page === "resolution"
        ? "Resolution"
        : root.page === "refresh"
          ? "Refresh rate"
          : root.selectedOutput.description || root.selectedName
    subtitle: root.page === "overview"
      ? `${root.activeOutputCount} active`
      : root.page === "resolution" || root.page === "refresh"
        ? root.selectedOutput.description || root.selectedName
      : root.selectedOutput.description?.length > 0
        ? root.selectedName
        : "Display settings"
    leadingActionIcon: "󰁍"
    leadingAction: root.page !== "overview" ? () => root.goBack() : null

    Loader {
      width: parent.width
      sourceComponent: root.page === "overview"
        ? overviewComponent
        : root.page === "resolution"
          ? resolutionComponent
          : root.page === "refresh"
            ? refreshComponent
            : detailComponent
    }

    Text {
      visible: root.error.length > 0
      width: parent.width
      text: root.error
      color: root.theme.palette.urgent
      wrapMode: Text.Wrap
      font.family: root.theme.panel.font
      font.pixelSize: root.theme.typography.readoutSize
    }
  }

  Component {
    id: overviewComponent

    Column {
      width: parent?.width ?? 0
      spacing: root.theme.panel.spacing

      PanelSectionLabel {
        visible: root.displayState.brightness.available
        theme: root.theme
        navigationSection: "brightness"
        text: "Brightness"
      }

      PanelSlider {
        visible: root.displayState.brightness.available
        width: parent.width
        theme: root.theme
        navigationSection: "brightness"
        value: root.currentBrightness / 100
        stepSize: 0.05
        onEdited: value => root.queueBrightness(value)
      }

      PanelSectionLabel {
        theme: root.theme
        navigationSection: "displays"
        text: "Connected displays"
      }

      Repeater {
        model: root.displayState.outputs

        PanelRow {
          required property var modelData

          width: parent.width
          theme: root.theme
          navigationSection: "displays"
          icon: modelData.name.match(/^(eDP|LVDS|DSI)-/) ? "󰌢" : "󰍹"
          title: modelData.description || modelData.name
          detail: root.outputDetail(modelData)
          action: () => root.openDetails(modelData.name)
        }
      }

      PanelAction {
        visible: root.activeOutputCount > 1
        width: parent.width
        theme: root.theme
        navigationSection: "displays"
        icon: "󰍹"
        text: "Arrange displays"
        action: () => root.arrangeRequested()
      }
    }
  }

  Component {
    id: detailComponent

    Column {
      width: parent?.width ?? 0
      spacing: root.theme.panel.spacing

      PanelRow {
        readonly property bool canToggle: !root.draftEnabled
          || !root.selectedOutput.enabled
          || root.activeOutputCount > 1

        visible: canToggle
        width: parent.width
        theme: root.theme
        navigationSection: "enabled"
        title: "Enabled"
        switchVisible: true
        switchActive: root.draftEnabled
        action: () => root.setEnabled(!root.draftEnabled)
      }

      PanelSectionLabel {
        visible: root.draftEnabled
        theme: root.theme
        navigationSection: "mode"
        text: "Display mode"
      }

      PanelRow {
        visible: root.draftEnabled
        width: parent.width
        theme: root.theme
        navigationSection: "mode"
        title: "Resolution"
        detail: root.resolutionDetail()
        action: () => root.page = "resolution"
      }

      PanelRow {
        visible: root.draftEnabled
          && root.draftResolution !== "preferred"
          && root.refreshOptions.length > 0
        width: parent.width
        theme: root.theme
        navigationSection: "mode"
        title: "Refresh rate"
        detail: root.refreshDetail()
        action: () => root.page = "refresh"
      }

      PanelSectionLabel {
        visible: root.draftEnabled
        theme: root.theme
        navigationSection: "scale"
        text: "Scale"
      }

      Flow {
        visible: root.draftEnabled
        width: parent.width
        spacing: 4

        Repeater {
          model: [{ "value": "auto", "label": "Auto" }].concat(
            (root.selectedOutput.scalePresets ?? []).map(value => ({
              "value": value,
              "label": `${Number(value.toFixed(2))}×`
            })))

          PanelAction {
            required property var modelData

            width: 58
            theme: root.theme
            navigationSection: "scale"
            text: modelData.label
            selected: root.scaleSelected(modelData.value)
            action: () => root.draftScale = modelData.value
          }
        }
      }

      PanelAction {
        visible: root.draftDirty && !DisplayConfirmationState.previewing
        width: parent.width
        theme: root.theme
        navigationSection: "apply"
        icon: "󰄬"
        text: "Apply changes"
        action: () => root.applyDraft()
      }
    }
  }

  Component {
    id: resolutionComponent

    Column {
      width: parent?.width ?? 0
      spacing: root.theme.panel.spacing

      PanelRow {
        width: parent.width
        theme: root.theme
        navigationSection: "resolution"
        title: "Preferred"
        detail: "automatic"
        selected: root.draftResolution === "preferred"
        action: () => root.selectResolution("preferred")
      }

      Repeater {
        model: root.resolutionOptions

        PanelRow {
          required property var modelData

          width: parent.width
          theme: root.theme
          navigationSection: "resolution"
          title: `${modelData.width} × ${modelData.height}`
          selected: root.draftResolution === modelData.value
          action: () => root.selectResolution(modelData.value)
        }
      }
    }
  }

  Component {
    id: refreshComponent

    Column {
      width: parent?.width ?? 0
      spacing: root.theme.panel.spacing

      Repeater {
        model: root.refreshOptions

        PanelRow {
          required property var modelData

          width: parent.width
          theme: root.theme
          navigationSection: "refresh"
          title: `${Number(modelData.refreshRate.toFixed(3))} Hz`
          selected: root.draftMode === modelData.value
          action: () => root.selectRefresh(modelData.value)
        }
      }
    }
  }
}
