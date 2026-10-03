import QtQuick

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
    // Lines one unit wide on half-unit coordinates stay sharp at scale 1; the
    // waves are spaced so neighbours keep a clear gap between them.
    const radii = [3, 6, 9].map(radius => radius * scale)
    const activeWaves = muted ? 0 : Math.min(radii.length, Math.ceil(volume * radii.length))
    const centerY = Math.floor(height / 2) + 0.5 * scale
    const offset = Math.round((width - 16 * scale) / 2 - scale)

    context.clearRect(0, 0, width, height)
    context.strokeStyle = indicatorColor
    context.lineWidth = scale
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
      context.arc(offset + 7.5 * scale, centerY, radii[index], -0.78, 0.78)
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
