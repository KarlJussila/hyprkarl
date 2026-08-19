import QtQuick
import QtQuick.Window

Canvas {
  id: root

  property real volume: 0
  property bool muted: false
  property color indicatorColor: "white"
  property real nativeScale: 1

  implicitWidth: 17 * nativeScale
  implicitHeight: 14 * nativeScale

  onVolumeChanged: requestPaint()
  onMutedChanged: requestPaint()
  onIndicatorColorChanged: requestPaint()
  onNativeScaleChanged: requestPaint()

  onPaint: {
    const context = getContext("2d")
    const scale = root.nativeScale
    const centerY = height / 2
    const waves = muted ? 0 : volume <= 0 ? 0 : volume <= 0.25 ? 1 : volume <= 0.5 ? 2 : volume <= 0.75 ? 3 : 4
    const radii = [3, 4.8, 6.6, 8.4].map(radius => radius * scale)
    const drawnWidth = waves > 0
      ? 7.4 * scale + radii[waves - 1] + 1.2 * scale
      : 9.2 * scale
    const offset = (width - drawnWidth) / 2 + 0.5 * scale

    context.clearRect(0, 0, width, height)
    context.strokeStyle = indicatorColor
    context.lineWidth = 2 * scale / Screen.devicePixelRatio
    context.lineCap = "round"
    context.lineJoin = "round"

    context.beginPath()
    context.moveTo(offset + 1.5 * scale, centerY - 2 * scale)
    context.lineTo(offset + 4.5 * scale, centerY - 2 * scale)
    context.lineTo(offset + 8.5 * scale, centerY - 5 * scale)
    context.lineTo(offset + 8.5 * scale, centerY + 5 * scale)
    context.lineTo(offset + 4.5 * scale, centerY + 2 * scale)
    context.lineTo(offset + 1.5 * scale, centerY + 2 * scale)
    context.closePath()
    context.stroke()

    for (let index = 0; index < waves; index++) {
      context.beginPath()
      context.arc(offset + 7.4 * scale, centerY, radii[index], -0.78, 0.78)
      context.stroke()
    }

    if (muted) {
      context.beginPath()
      context.moveTo(offset + 3 * scale, centerY - 5.2 * scale)
      context.lineTo(offset + 11 * scale, centerY + 5.2 * scale)
      context.stroke()
    }
  }
}
