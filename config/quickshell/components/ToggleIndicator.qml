import QtQuick

Item {
  id: root

  property bool active: false
  property string onGlyph: ""
  property string offGlyph: ""
  required property var theme

  property real progress: active ? 1 : 0
  property color surfaceColor: theme.barSurface
  property color accentColor: theme.accent
  property color outlineColor: theme.border
  property color foregroundColor: theme.foreground
  property color trackColor: active ? accentColor : surfaceColor
  property color borderColor: active ? accentColor : outlineColor

  implicitWidth: 28
  implicitHeight: 18

  Behavior on progress {
    NumberAnimation { duration: 140; easing.type: Easing.InOutCubic }
  }

  Behavior on trackColor { ColorAnimation { duration: 140 } }
  Behavior on borderColor { ColorAnimation { duration: 140 } }

  Item {
    width: 28
    height: 18
    anchors.centerIn: parent

    Canvas {
      id: canvas
      anchors.fill: parent

      onPaint: {
        const context = getContext("2d")
        const thumbX = 1 + root.progress * 10

        function roundedRect(x, y, width, height, radius) {
          context.beginPath()
          context.arc(x + width - radius, y + radius, radius, -Math.PI / 2, 0)
          context.arc(x + width - radius, y + height - radius, radius, 0, Math.PI / 2)
          context.arc(x + radius, y + height - radius, radius, Math.PI / 2, Math.PI)
          context.arc(x + radius, y + radius, radius, Math.PI, Math.PI * 1.5)
          context.closePath()
        }

        context.clearRect(0, 0, width, height)
        context.lineWidth = 2

        roundedRect(2, 3, 24, 12, 6)
        context.fillStyle = root.trackColor
        context.fill()
        context.strokeStyle = root.borderColor
        context.stroke()

        roundedRect(thumbX, 1, 16, 16, 8)
        context.fillStyle = root.surfaceColor
        context.fill()
        context.strokeStyle = root.borderColor
        context.stroke()
      }
    }

    Text {
      x: 1 + root.progress * 10
      y: 1
      width: 16
      height: 16
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      text: root.active ? root.onGlyph : root.offGlyph
      color: root.foregroundColor
      font.family: root.theme.uiFontFamily
      font.pixelSize: 9
    }
  }

  onProgressChanged: canvas.requestPaint()
  onTrackColorChanged: canvas.requestPaint()
  onBorderColorChanged: canvas.requestPaint()
  onSurfaceColorChanged: canvas.requestPaint()
  onAccentColorChanged: canvas.requestPaint()
  onOutlineColorChanged: canvas.requestPaint()
}
