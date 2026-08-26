import QtQuick
import QtQuick.Window

Canvas {
  id: root

  property real volume: 0
  property bool muted: false
  property color indicatorColor: "white"
  property color inactiveWaveColor: indicatorColor
  property real nativeScale: 1

  implicitWidth: 17 * nativeScale
  implicitHeight: 14 * nativeScale

  onVolumeChanged: requestPaint()
  onMutedChanged: requestPaint()
  onIndicatorColorChanged: requestPaint()
  onInactiveWaveColorChanged: requestPaint()
  onNativeScaleChanged: requestPaint()

  onPaint: {
    const context = getContext("2d")
    const scale = root.nativeScale
    const centerY = height / 2
    const activeWaves = muted ? 0 : volume <= 0 ? 0 : volume <= 0.25 ? 1 : volume <= 0.5 ? 2 : volume <= 0.75 ? 3 : 4
    const radii = [3, 4.8, 6.6, 8.4].map(radius => radius * scale)
    const drawnWidth = 7.4 * scale + radii[radii.length - 1] + 1.2 * scale
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

    for (let index = 0; index < radii.length; index++) {
      context.strokeStyle = index < activeWaves
        ? indicatorColor
        : inactiveWaveColor
      context.beginPath()
      context.arc(offset + 7.4 * scale, centerY, radii[index], -0.78, 0.78)
      context.stroke()
    }

    if (muted) {
      context.strokeStyle = indicatorColor
      context.beginPath()
      context.moveTo(offset + 3 * scale, centerY - 5.2 * scale)
      context.lineTo(offset + 11 * scale, centerY + 5.2 * scale)
      context.stroke()
    }
  }
}
