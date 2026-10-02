pragma ComponentBehavior: Bound

import QtQuick
import "../../ui/modal"

Modal {
  id: root

  required property var shellContext

  context: shellContext
  name: DisplayArrangementState.surface
  title: "Arrange displays"
  subtitle: "Drag to position · Right-click a frame to rotate clockwise"
  preferredWidth: shellContext.theme.displayArrangement.width
  preferredHeight: shellContext.theme.displayArrangement.height

  body: Component {
    Item {
      id: arrangement

      readonly property real canvasPadding: root.shellContext.theme.menu.entryPadding * 2
      readonly property real layoutScale: Math.max(0.01, Math.min(
        (canvas.width - canvasPadding * 2) / DisplayArrangementState.viewportWidth,
        (canvas.height - canvasPadding * 2) / DisplayArrangementState.viewportHeight
      ))
      readonly property real layoutWidth: DisplayArrangementState.viewportWidth
        * layoutScale
      readonly property real layoutHeight: DisplayArrangementState.viewportHeight
        * layoutScale
      readonly property real layoutX: (canvas.width - layoutWidth) / 2
      readonly property real layoutY: (canvas.height - layoutHeight) / 2

      function snapPosition(
        name: string,
        candidateX: real,
        candidateY: real,
        width: real,
        height: real
      ): var {
        const threshold = 12 / layoutScale
        let snappedX = candidateX
        let snappedY = candidateY
        let closestX = threshold
        let closestY = threshold

        for (let index = 0; index < DisplayArrangementState.outputs.count; index++) {
          const other = DisplayArrangementState.outputs.get(index)
          if (other.name === name) continue
          const xCandidates = [
            other.positionX,
            other.positionX + other.logicalWidth,
            other.positionX - width,
            other.positionX + other.logicalWidth - width
          ]
          const yCandidates = [
            other.positionY,
            other.positionY + other.logicalHeight,
            other.positionY - height,
            other.positionY + other.logicalHeight - height
          ]
          for (const value of xCandidates) {
            const distance = Math.abs(candidateX - value)
            if (distance < closestX) {
              closestX = distance
              snappedX = value
            }
          }
          for (const value of yCandidates) {
            const distance = Math.abs(candidateY - value)
            if (distance < closestY) {
              closestY = distance
              snappedY = value
            }
          }
        }
        return Qt.point(Math.round(snappedX), Math.round(snappedY))
      }

      Text {
        id: status

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: implicitHeight
        text: DisplayArrangementState.loading
          ? "Reading the current layout…"
          : DisplayArrangementState.error
              || DisplayArrangementState.validationError
        color: (DisplayArrangementState.error.length > 0
          || DisplayArrangementState.validationError.length > 0)
          ? root.shellContext.theme.palette.urgent
          : root.shellContext.theme.menu.foreground
        font.family: root.shellContext.theme.menu.font
        font.pixelSize: root.shellContext.theme.typography.readoutSize
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
      }

      Rectangle {
        id: canvas

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: status.bottom
        anchors.bottom: positionReadout.top
        anchors.topMargin: root.shellContext.theme.menu.entryPadding
        anchors.bottomMargin: root.shellContext.theme.menu.entryPadding
        color: "transparent"
        border.color: root.shellContext.theme.menu.border
        border.width: root.shellContext.theme.menu.innerBorderWidth
        radius: root.shellContext.theme.menu.entryRadius
        clip: true

        Repeater {
          model: DisplayArrangementState.outputs

          Rectangle {
            id: displayFrame

            required property string name
            required property string description
            required property real positionX
            required property real positionY
            required property int outputTransform
            required property real logicalWidth
            required property real logicalHeight
            property real dragStartX: 0
            property real dragStartY: 0
            readonly property bool selected:
              DisplayArrangementState.selectedName === name

            x: arrangement.layoutX
              + (positionX - DisplayArrangementState.viewportX)
                * arrangement.layoutScale
            y: arrangement.layoutY
              + (positionY - DisplayArrangementState.viewportY)
                * arrangement.layoutScale
            width: logicalWidth * arrangement.layoutScale
            height: logicalHeight * arrangement.layoutScale
            color: "transparent"
            border.color: selected
              ? root.shellContext.theme.menu.accent
              : root.shellContext.theme.menu.border
            border.width: selected
              ? Math.max(2, root.shellContext.theme.menu.selectionBorderWidth)
              : Math.max(1, root.shellContext.theme.menu.innerBorderWidth)
            radius: root.shellContext.theme.menu.entryRadius

            Rectangle {
              readonly property int quarterTurn:
                displayFrame.outputTransform % 4
              readonly property bool vertical:
                quarterTurn === 1 || quarterTurn === 3
              readonly property real edge:
                root.shellContext.theme.displayArrangement.bezelFraction
              readonly property real stroke: Math.max(
                1, root.shellContext.theme.menu.innerBorderWidth)

              x: quarterTurn === 1
                ? displayFrame.width * edge
                : quarterTurn === 3
                  ? displayFrame.width * (1 - edge) - stroke
                  : displayFrame.border.width
              y: quarterTurn === 0
                ? displayFrame.height * (1 - edge) - stroke
                : quarterTurn === 2
                  ? displayFrame.height * edge
                  : displayFrame.border.width
              width: vertical
                ? stroke
                : displayFrame.width - displayFrame.border.width * 2
              height: vertical
                ? displayFrame.height - displayFrame.border.width * 2
                : stroke
              color: displayFrame.border.color
              opacity: 0.7
            }

            Column {
              anchors.centerIn: parent
              width: Math.max(0,
                parent.width - root.shellContext.theme.menu.entryPadding * 2)
              spacing: 2

              Text {
                width: parent.width
                text: displayFrame.description || displayFrame.name
                color: displayFrame.selected
                  ? root.shellContext.theme.menu.accent
                  : root.shellContext.theme.menu.foreground
                font.family: root.shellContext.theme.menu.font
                font.pixelSize: root.shellContext.theme.menu.fontSize
                font.weight: root.shellContext.theme.menu.fontWeight
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
              }

              Text {
                visible: displayFrame.description.length > 0
                width: parent.width
                text: displayFrame.name
                color: root.shellContext.theme.menu.foreground
                opacity: 0.6
                font.family: root.shellContext.theme.typography.monoFamily
                font.pixelSize: root.shellContext.theme.typography.readoutSize
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
              }
            }

            HoverHandler { cursorShape: Qt.OpenHandCursor }

            TapHandler {
              acceptedButtons: Qt.LeftButton
              onTapped: DisplayArrangementState.select(displayFrame.name)
            }

            TapHandler {
              acceptedButtons: Qt.RightButton
              enabled: !DisplayArrangementState.loading
                && !DisplayArrangementState.applying
              onTapped: DisplayArrangementState.rotateClockwise(
                displayFrame.name)
            }

            DragHandler {
              id: drag

              target: null
              enabled: !DisplayArrangementState.loading
                && !DisplayArrangementState.applying
              onActiveChanged: {
                if (!active) return
                displayFrame.dragStartX = displayFrame.positionX
                displayFrame.dragStartY = displayFrame.positionY
                DisplayArrangementState.select(displayFrame.name)
              }
              onActiveTranslationChanged: {
                if (!active) return
                const position = arrangement.snapPosition(
                  displayFrame.name,
                  displayFrame.dragStartX
                    + activeTranslation.x / arrangement.layoutScale,
                  displayFrame.dragStartY
                    + activeTranslation.y / arrangement.layoutScale,
                  displayFrame.logicalWidth,
                  displayFrame.logicalHeight
                )
                DisplayArrangementState.move(
                  displayFrame.name, position.x, position.y)
              }
            }
          }
        }
      }

      Text {
        id: positionReadout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: implicitHeight
        readonly property int selectedIndex:
          DisplayArrangementState.indexOf(DisplayArrangementState.selectedName)
        readonly property var selectedOutput: selectedIndex >= 0
          ? DisplayArrangementState.outputs.get(selectedIndex)
          : null
        text: selectedOutput
          ? `${selectedOutput.name}  ${selectedOutput.positionX}, ${selectedOutput.positionY}  ·  ${selectedOutput.outputTransform % 4 * 90}°`
          : ""
        color: root.shellContext.theme.menu.foreground
        opacity: 0.7
        font.family: root.shellContext.theme.typography.monoFamily
        font.pixelSize: root.shellContext.theme.typography.readoutSize
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }

  footer: Component {
    Item {
      implicitHeight: 34

      ModalButton {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        theme: root.shellContext.theme
        text: "Reset"
        enabled: DisplayArrangementState.dirty
          && !DisplayArrangementState.applying
        action: () => DisplayArrangementState.reset()
      }

      Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.shellContext.theme.menu.entryPadding

        ModalButton {
          theme: root.shellContext.theme
          text: "Cancel"
          enabled: !DisplayArrangementState.applying
          action: () => DisplayArrangementState.close()
        }

        ModalButton {
          theme: root.shellContext.theme
          text: DisplayArrangementState.applying ? "Applying…" : "Apply"
          accent: true
          enabled: DisplayArrangementState.dirty
            && DisplayArrangementState.validationError.length === 0
            && !DisplayArrangementState.applying
          action: () => DisplayArrangementState.apply()
        }
      }
    }
  }
}
