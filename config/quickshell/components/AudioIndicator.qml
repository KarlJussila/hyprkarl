import QtQuick

Canvas {
  id: root

  property real volume: 0
  property bool muted: false
  property color indicatorColor: "white"

  implicitWidth: 17
  implicitHeight: 14

  onVolumeChanged: requestPaint()
  onMutedChanged: requestPaint()
  onIndicatorColorChanged: requestPaint()

  onPaint: {
    const context = getContext("2d")
    const centerY = height / 2
    const waves = muted ? 0 : volume <= 0 ? 0 : volume <= 0.25 ? 1 : volume <= 0.5 ? 2 : volume <= 0.75 ? 3 : 4
    const radii = [3, 4.8, 6.6, 8.4]
    const drawnWidth = waves > 0 ? 7.4 + radii[waves - 1] + 1.2 : 9.2
    const offset = (width - drawnWidth) / 2 + 0.5

    context.clearRect(0, 0, width, height)
    context.strokeStyle = indicatorColor
    context.lineWidth = 1.4
    context.lineCap = "round"
    context.lineJoin = "round"

    context.beginPath()
    context.moveTo(offset + 1.5, centerY - 2)
    context.lineTo(offset + 4.5, centerY - 2)
    context.lineTo(offset + 8.5, centerY - 5)
    context.lineTo(offset + 8.5, centerY + 5)
    context.lineTo(offset + 4.5, centerY + 2)
    context.lineTo(offset + 1.5, centerY + 2)
    context.closePath()
    context.stroke()

    for (let index = 0; index < waves; index++) {
      context.beginPath()
      context.arc(offset + 7.4, centerY, radii[index], -0.78, 0.78)
      context.stroke()
    }

    if (muted) {
      context.beginPath()
      context.moveTo(offset + 3, centerY - 5.2)
      context.lineTo(offset + 11, centerY + 5.2)
      context.stroke()
    }
  }
}
