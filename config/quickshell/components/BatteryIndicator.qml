import QtQuick

Item {
  id: root

  property real level: 0
  property bool charging: false
  property color surfaceColor: "transparent"
  property color indicatorColor: "white"
  property color lowColor: "red"
  property color accentColor: "white"
  property real lowThreshold: 0.15

  readonly property color fillColor: level <= lowThreshold ? lowColor : indicatorColor

  implicitWidth: 18
  implicitHeight: 10

  Item {
    width: 18
    height: 10
    anchors.centerIn: parent

    Canvas {
      id: canvas
      anchors.fill: parent

      onPaint: {
        const context = getContext("2d")
        const clampedLevel = Math.max(0, Math.min(1, root.level))
        const rawFillWidth = 12 * clampedLevel
        const fillWidth = clampedLevel > 0 ? Math.min(12, Math.max(1, rawFillWidth)) : 0

        context.clearRect(0, 0, width, height)

        context.fillStyle = root.surfaceColor
        context.fillRect(2, 1, 14, 8)

        if (fillWidth > 0) {
          context.fillStyle = root.fillColor
          context.fillRect(3, 2, fillWidth, 6)
        }

        context.strokeStyle = root.indicatorColor
        context.lineWidth = 1
        context.strokeRect(2, 1, 14, 8)

        context.fillStyle = root.indicatorColor
        context.fillRect(16, 3, 2, 4)
      }
    }

    Text {
      x: 2
      y: 0
      width: 14
      height: 10
      visible: root.charging
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      text: "󱐋"
      color: root.accentColor
      font.family: "JetBrains Mono Nerd Font Propo"
      font.pixelSize: 8
    }
  }

  onLevelChanged: canvas.requestPaint()
  onSurfaceColorChanged: canvas.requestPaint()
  onIndicatorColorChanged: canvas.requestPaint()
  onLowColorChanged: canvas.requestPaint()
  onFillColorChanged: canvas.requestPaint()
}
