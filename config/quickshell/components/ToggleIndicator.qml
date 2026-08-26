import QtQuick

Item {
  id: root

  property bool active: false
  property string onGlyph: ""
  property string offGlyph: ""
  property var appearance: ({})
  required property var theme

  readonly property var defaults: theme.switchAppearance
  readonly property string variant: appearance.variant ?? "switch"
  readonly property real trackLength: appearance.trackLength ?? defaults.trackLength
  readonly property real trackHeight: appearance.trackHeight ?? defaults.trackHeight
  readonly property real trackRadius: appearance.trackRadius ?? defaults.trackRadius
  readonly property real thumbSize: appearance.thumbSize ?? defaults.thumbSize
  readonly property real thumbRadius: appearance.thumbRadius ?? defaults.thumbRadius
  readonly property real thumbPadding: appearance.thumbPadding ?? defaults.thumbPadding
  readonly property real indicatorBorderWidth:
    appearance.borderWidth ?? defaults.borderWidth
  readonly property bool markFilled:
    appearance.markFilled ?? defaults.markFilled ?? false
  readonly property string glyphFontFamily:
    appearance.fontFamily ?? defaults.fontFamily
  readonly property real glyphFontSize: appearance.fontSize ?? defaults.fontSize
  readonly property var activeGlyphOffset:
    appearance.onGlyphOffset ?? defaults.onGlyphOffset
  readonly property var inactiveGlyphOffset:
    appearance.offGlyphOffset ?? defaults.offGlyphOffset
  readonly property int transitionDuration:
    appearance.transitionDuration ?? defaults.transitionDuration

  readonly property real strokeInset:
    Math.max(1, Math.ceil(indicatorBorderWidth / 2))
  readonly property real contentWidth: variant === "mark"
    ? thumbSize + strokeInset * 2
    : trackLength + thumbSize + strokeInset * 2 - thumbPadding * 2
  readonly property real contentHeight:
    (variant === "mark" ? thumbSize : Math.max(thumbSize, trackHeight))
      + strokeInset * 2
  readonly property real trackX:
    strokeInset + thumbSize / 2 - thumbPadding
  readonly property real trackY: (contentHeight - trackHeight) / 2
  readonly property real thumbY: (contentHeight - thumbSize) / 2
  readonly property real thumbX: variant === "mark"
    ? strokeInset
    : strokeInset + progress * (contentWidth - thumbSize - strokeInset * 2)
  readonly property var glyphOffset:
    active ? activeGlyphOffset : inactiveGlyphOffset

  property real progress: active ? 1 : 0
  property color surfaceColor: theme.barSurface
  property color accentColor: theme.accent
  property color outlineColor: theme.border
  property color foregroundColor: theme.foreground
  property color trackColor: active ? accentColor : surfaceColor
  property color borderColor: active ? accentColor : outlineColor
  readonly property color thumbFillColor:
    variant === "mark" && markFilled ? trackColor : surfaceColor

  implicitWidth: Math.ceil(contentWidth)
  implicitHeight: Math.ceil(contentHeight)

  Behavior on progress {
    NumberAnimation {
      duration: root.transitionDuration
      easing.type: Easing.InOutCubic
    }
  }

  Behavior on trackColor {
    ColorAnimation { duration: root.transitionDuration }
  }

  Behavior on borderColor {
    ColorAnimation { duration: root.transitionDuration }
  }

  Canvas {
    id: canvas

    anchors.centerIn: parent
    width: root.contentWidth
    height: root.contentHeight

    function roundedRect(context, x, y, width, height, radius): void {
      const resolvedRadius = Math.max(0, Math.min(radius, width / 2, height / 2))
      context.beginPath()
      if (resolvedRadius === 0) {
        context.rect(x, y, width, height)
        return
      }
      context.arc(
        x + width - resolvedRadius,
        y + resolvedRadius,
        resolvedRadius,
        -Math.PI / 2,
        0)
      context.arc(
        x + width - resolvedRadius,
        y + height - resolvedRadius,
        resolvedRadius,
        0,
        Math.PI / 2)
      context.arc(
        x + resolvedRadius,
        y + height - resolvedRadius,
        resolvedRadius,
        Math.PI / 2,
        Math.PI)
      context.arc(
        x + resolvedRadius,
        y + resolvedRadius,
        resolvedRadius,
        Math.PI,
        Math.PI * 1.5)
      context.closePath()
    }

    onPaint: {
      const context = getContext("2d")
      context.clearRect(0, 0, width, height)
      context.lineWidth = root.indicatorBorderWidth

      if (root.variant === "switch") {
        roundedRect(
          context,
          root.trackX,
          root.trackY,
          root.trackLength,
          root.trackHeight,
          root.trackRadius)
        context.fillStyle = root.trackColor
        context.fill()
        if (root.indicatorBorderWidth > 0) {
          context.strokeStyle = root.borderColor
          context.stroke()
        }
      }

      roundedRect(
        context,
        root.thumbX,
        root.thumbY,
        root.thumbSize,
        root.thumbSize,
        root.thumbRadius)
      context.fillStyle = root.thumbFillColor
      context.fill()
      if (root.indicatorBorderWidth > 0) {
        context.strokeStyle = root.borderColor
        context.stroke()
      }
    }
  }

  Text {
    x: canvas.x + root.thumbX + root.glyphOffset[0]
    y: canvas.y + root.thumbY + root.glyphOffset[1]
    width: root.thumbSize
    height: root.thumbSize
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    text: root.active ? root.onGlyph : root.offGlyph
    color: root.foregroundColor
    font.family: root.glyphFontFamily
    font.pixelSize: root.glyphFontSize
  }

  onProgressChanged: canvas.requestPaint()
  onTrackColorChanged: canvas.requestPaint()
  onBorderColorChanged: canvas.requestPaint()
  onThumbFillColorChanged: canvas.requestPaint()
  onSurfaceColorChanged: canvas.requestPaint()
  onContentWidthChanged: canvas.requestPaint()
  onContentHeightChanged: canvas.requestPaint()
  onVariantChanged: canvas.requestPaint()
  onTrackXChanged: canvas.requestPaint()
  onTrackYChanged: canvas.requestPaint()
  onTrackLengthChanged: canvas.requestPaint()
  onTrackHeightChanged: canvas.requestPaint()
  onTrackRadiusChanged: canvas.requestPaint()
  onThumbXChanged: canvas.requestPaint()
  onThumbYChanged: canvas.requestPaint()
  onThumbSizeChanged: canvas.requestPaint()
  onThumbRadiusChanged: canvas.requestPaint()
  onIndicatorBorderWidthChanged: canvas.requestPaint()
}
