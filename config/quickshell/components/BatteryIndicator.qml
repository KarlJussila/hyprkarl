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
      }
    }

    Text {
      x: 2 * root.nativeScale
      y: 0
      width: 14 * root.nativeScale
      height: 10 * root.nativeScale
      visible: root.charging
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      text: "󱐋"
      color: root.accentColor
      font.family: "JetBrains Mono Nerd Font Propo"
      font.pixelSize: 8 * root.nativeScale
    }
  }

  onLevelChanged: canvas.requestPaint()
  onSurfaceColorChanged: canvas.requestPaint()
  onIndicatorColorChanged: canvas.requestPaint()
  onLowColorChanged: canvas.requestPaint()
  onFillColorChanged: canvas.requestPaint()
  onNativeScaleChanged: canvas.requestPaint()
}
