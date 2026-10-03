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
  property real nativeScale: 1

  readonly property color fillColor: level <= lowThreshold ? lowColor : indicatorColor
  readonly property var boltPoints: [[11, 0], [6.5, 5.6], [9, 5.6], [7, 10], [11.5, 4.4], [9, 4.4]]

  implicitWidth: 18 * nativeScale
  implicitHeight: 10 * nativeScale

  Item {
    width: 18 * root.nativeScale
    height: 10 * root.nativeScale
    anchors.centerIn: parent

    Canvas {
      id: canvas
      anchors.fill: parent

      onPaint: {
        const context = getContext("2d")
        const scale = root.nativeScale
        const clampedLevel = Math.max(0, Math.min(1, root.level))
        const rawFillWidth = 12 * scale * clampedLevel
        const fillWidth = clampedLevel > 0
          ? Math.min(12 * scale, Math.max(scale, rawFillWidth))
          : 0

        context.clearRect(0, 0, width, height)

        context.fillStyle = root.surfaceColor
        context.fillRect(2 * scale, scale, 14 * scale, 8 * scale)

        if (fillWidth > 0) {
          context.fillStyle = root.fillColor
          context.fillRect(3 * scale, 2 * scale, fillWidth, 6 * scale)
        }

        context.strokeStyle = root.indicatorColor
        context.lineWidth = scale
        context.strokeRect(2 * scale, scale, 14 * scale, 8 * scale)

        context.fillStyle = root.indicatorColor
        context.fillRect(16 * scale, 3 * scale, 2 * scale, 4 * scale)

        if (!root.charging)
          return

        // The bolt sits in a cutout through the fill and outline, so it stays
        // visible whatever color is behind it.
        context.beginPath()
        root.boltPoints.forEach(([x, y], index) => {
          if (index === 0)
            context.moveTo(x * scale, y * scale)
          else
            context.lineTo(x * scale, y * scale)
        })
        context.closePath()

        context.globalCompositeOperation = "destination-out"
        context.strokeStyle = "black"
        context.fillStyle = "black"
        context.lineJoin = "round"
        context.lineWidth = 2 * scale
        context.stroke()
        context.fill()
        context.globalCompositeOperation = "source-over"

        context.fillStyle = root.accentColor
        context.fill()
      }
    }
  }

  onLevelChanged: canvas.requestPaint()
  onChargingChanged: canvas.requestPaint()
  onAccentColorChanged: canvas.requestPaint()
  onSurfaceColorChanged: canvas.requestPaint()
  onIndicatorColorChanged: canvas.requestPaint()
  onLowColorChanged: canvas.requestPaint()
  onFillColorChanged: canvas.requestPaint()
  onNativeScaleChanged: canvas.requestPaint()
}
