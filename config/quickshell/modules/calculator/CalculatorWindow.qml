pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../../ui/modal"

PickerWindow {
  id: root

  readonly property bool active: CalculatorState.active
    && output.name === OverlayState.screenName
  readonly property real rowHeight: 42
  readonly property var rows: buildRows()
  property string evaluationExpression: ""
  property string evaluationResult: ""
  property string evaluationError: ""
  property bool pointerPositionKnown: false
  property point pointerPosition: Qt.point(0, 0)
  property bool selectionVisible: true

  shown: active
  title: "Calculator"
  placeholder: "Calculate…"
  requestedWidth: theme.calculator.width
  requestedBodyHeight: rowHeight * Math.max(1,
    Math.min(theme.calculator.historyRows, rows.length))

  function buildRows(): var {
    const rows = []
    if (query.trim().length > 0 && evaluationResult.length > 0) {
      rows.push({
        "expression": query.trim(),
        "result": evaluationResult,
        "live": true
      })
    }
    for (const entry of CalculatorState.history) {
      if (entry.expression !== query.trim()) rows.push(entry)
    }
    return rows.slice(0, theme.calculator.historyRows)
  }

  function resetSelection(): void {
    pointerPositionKnown = false
    calculationList.currentIndex = calculationList.count > 0 ? 0 : -1
    selectionVisible = calculationList.currentIndex >= 0
    if (calculationList.count > 0) calculationList.positionViewAtBeginning()
  }

  function selectIndex(index): void {
    if (calculationList.count === 0) return
    calculationList.currentIndex = Math.max(0,
      Math.min(calculationList.count - 1, index))
    calculationList.positionViewAtIndex(calculationList.currentIndex,
      ListView.Contain)
  }

  function moveSelection(offset): void {
    if (calculationList.count === 0) return
    selectIndex(calculationList.currentIndex < 0
      ? (offset > 0 ? 0 : calculationList.count - 1)
      : calculationList.currentIndex + offset)
    selectionVisible = calculationList.currentIndex >= 0
  }

  function copyEntry(entry): void {
    CalculatorState.addHistory(entry.expression, entry.result)
    CalculatorState.close()
    Quickshell.execDetached(["uwsm-app", "--", "wl-copy", entry.result])
  }

  function handleKey(event, editing): void {
    if (event.key === Qt.Key_Escape) {
      if (editing && query.length > 0) query = ""
      else CalculatorState.close()
    } else if (event.key === Qt.Key_Down
        || (!editing && event.key === Qt.Key_J)) {
      moveSelection(1)
    } else if (event.key === Qt.Key_Up
        || (!editing && event.key === Qt.Key_K)) {
      moveSelection(-1)
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
        || (!editing && event.key === Qt.Key_Space)) {
      if (calculationList.currentIndex >= 0) {
        copyEntry(rows[calculationList.currentIndex])
      }
    } else {
      return
    }
    event.accepted = true
  }

  function evaluate(): void {
    const expression = query.trim()
    evaluationResult = ""
    evaluationError = ""
    if (expression.length === 0) {
      calculatorProcess.running = false
      return
    }
    evaluationExpression = expression
    calculatorProcess.exec(["qalc", "-t", expression])
  }

  onOutsideClicked: CalculatorState.close()
  onKeyPressed: (event, editing) => handleKey(event, editing)
  onQueryChanged: {
    evaluationResult = ""
    evaluationError = ""
    evaluationTimer.restart()
    Qt.callLater(resetSelection)
  }
  onRowsChanged: Qt.callLater(resetSelection)

  Timer {
    id: evaluationTimer
    interval: 45
    onTriggered: root.evaluate()
  }

  Process {
    id: calculatorProcess

    stdout: StdioCollector { id: calculationOutput }
    stderr: StdioCollector { id: calculationError }

    // qmllint disable signal-handler-parameters
    onExited: exitCode => {
      if (root.evaluationExpression !== root.query.trim()) return
      if (exitCode === 0) {
        root.evaluationResult = calculationOutput.text.trim()
        root.evaluationError = ""
      } else {
        root.evaluationResult = ""
        root.evaluationError = calculationError.text.trim() || "Invalid expression"
      }
    }
    // qmllint enable signal-handler-parameters
  }

  Text {
    anchors.fill: parent
    anchors.margins: root.theme.menu.entryPadding
    visible: calculationList.count === 0
    text: root.evaluationError.length > 0
      ? root.evaluationError
      : root.query.length > 0
        ? "Calculating…"
        : "No recent calculations"
    color: root.theme.menu.foreground
    opacity: 0.7
    font.family: root.theme.menu.font
    font.pixelSize: root.theme.menu.fontSize
    font.weight: root.theme.menu.fontWeight
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    wrapMode: Text.Wrap
  }

  ListView {
    id: calculationList

    anchors.fill: parent
    visible: count > 0
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    model: root.rows
    currentIndex: -1

    delegate: Item {
      id: row

      required property int index
      required property var modelData
      readonly property bool navigationCurrent:
        root.selectionVisible && row.ListView.isCurrentItem

      width: calculationList.width
      height: root.rowHeight

      Rectangle {
        anchors.fill: parent
        anchors.margins: root.theme.menu.entryMargin
        color: root.theme.menu.background
        border.color: row.navigationCurrent
          ? root.theme.menu.accent
          : "transparent"
        border.width: row.navigationCurrent
          ? root.theme.menu.selectionBorderWidth
          : 0
        radius: root.theme.menu.entryRadius

        Rectangle {
          anchors.fill: parent
          color: root.theme.menu.accent
          opacity: row.navigationCurrent
            ? root.theme.menu.selectionAccentOpacity
            : 0
          radius: parent.radius
        }

        Text {
          anchors.left: parent.left
          anchors.right: result.left
          anchors.leftMargin: root.theme.menu.entryPadding
          anchors.rightMargin: root.theme.menu.entryPadding
          anchors.verticalCenter: parent.verticalCenter
          text: row.modelData.expression
          color: root.theme.menu.foreground
          font.family: root.theme.menu.font
          font.pixelSize: root.theme.menu.fontSize
          font.weight: root.theme.menu.fontWeight
          elide: Text.ElideRight
        }

        Text {
          id: result

          anchors.right: parent.right
          anchors.rightMargin: root.theme.menu.entryPadding
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width * 0.46
          text: row.modelData.result
          color: root.theme.menu.foreground
          font.family: root.theme.menu.font
          font.pixelSize: root.theme.menu.fontSize
          font.weight: root.theme.menu.fontWeight
          horizontalAlignment: Text.AlignRight
          elide: Text.ElideLeft
        }
      }

      HoverHandler {
        cursorShape: Qt.PointingHandCursor
        onPointChanged: {
          const position = point.scenePosition
          const moved = root.pointerPositionKnown
            && (position.x !== root.pointerPosition.x
              || position.y !== root.pointerPosition.y)
          root.pointerPosition = Qt.point(position.x, position.y)
          root.pointerPositionKnown = true
          if (moved) {
            calculationList.currentIndex = row.index
            root.selectionVisible = true
          }
        }
      }
      TapHandler { onTapped: root.copyEntry(row.modelData) }
    }
  }
}
