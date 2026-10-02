import QtQuick

Item {
  id: root

  required property string edge
  required property string leftRole
  required property string rightRole
  required property var theme

  readonly property bool leftCurve: leftRole === "inner"
    && cornerStyle("screen", leftRole) === "curve"
  readonly property bool rightCurve: rightRole === "inner"
    && cornerStyle("screen", rightRole) === "curve"
  readonly property real leftInset: leftCurve ? theme.bar.island.curveSize : 0
  readonly property real rightInset: rightCurve ? theme.bar.island.curveSize : 0
  readonly property real bodyLeft: leftInset
  readonly property real bodyRight: width - rightInset
  readonly property string paintKey: [
    width,
    height,
    edge,
    leftRole,
    rightRole,
    theme.surfaces.bar,
    theme.palette.border,
    theme.metrics.borderWidth,
    theme.bar.island.radius,
    theme.bar.island.curveSize,
    theme.bar.island.curveRadius,
    JSON.stringify(theme.bar.island.corners),
    JSON.stringify(theme.bar.island.borders)
  ].join("|")

  function cornerStyle(longEdge: string, role: string): string {
    const key = longEdge + role.charAt(0).toUpperCase() + role.slice(1)
    return theme.bar.island.corners[key]
  }

  function borderEnabled(side: string): bool {
    return theme.bar.island.borders[side] === true
  }

  onPaintKeyChanged: canvas.requestPaint()

  Canvas {
    id: canvas

    anchors.fill: parent

    function roundedBody(context, x0, y0, x1, y1, topLeft, topRight, bottomRight, bottomLeft): void {
      context.beginPath()
      context.moveTo(x0 + topLeft, y0)
      context.lineTo(x1 - topRight, y0)
      if (topRight > 0) context.quadraticCurveTo(x1, y0, x1, y0 + topRight)
      else context.lineTo(x1, y0)
      context.lineTo(x1, y1 - bottomRight)
      if (bottomRight > 0) context.quadraticCurveTo(x1, y1, x1 - bottomRight, y1)
      else context.lineTo(x1, y1)
      context.lineTo(x0 + bottomLeft, y1)
      if (bottomLeft > 0) context.quadraticCurveTo(x0, y1, x0, y1 - bottomLeft)
      else context.lineTo(x0, y1)
      context.lineTo(x0, y0 + topLeft)
      if (topLeft > 0) context.quadraticCurveTo(x0, y0, x0 + topLeft, y0)
      else context.lineTo(x0, y0)
      context.closePath()
    }

    function strokeLine(context, startX, startY, endX, endY): void {
      context.beginPath()
      context.moveTo(startX, startY)
      context.lineTo(endX, endY)
      context.stroke()
    }

    function strokeCorner(context, startX, startY, controlX, controlY, endX, endY): void {
      context.beginPath()
      context.moveTo(startX, startY)
      context.quadraticCurveTo(controlX, controlY, endX, endY)
      context.stroke()
    }

    function strokeCurvedSide(context, side, x, startY, endY, y0, y1): void {
      const size = Math.min(root.theme.bar.island.curveSize, height)
      const control = root.theme.bar.island.curveRadius * 0.6
      const clipDepth = root.theme.metrics.borderWidth
      const top = root.edge === "top"

      context.beginPath()
      if (side === "left" && top) {
        context.moveTo(0, y0 - clipDepth)
        context.bezierCurveTo(root.bodyLeft - control, y0 - clipDepth, x, y0 - clipDepth, x, size - clipDepth)
        context.lineTo(x, endY)
      } else if (side === "right" && top) {
        context.moveTo(width, y0 - clipDepth)
        context.bezierCurveTo(root.bodyRight + control, y0 - clipDepth, x, y0 - clipDepth, x, size - clipDepth)
        context.lineTo(x, endY)
      } else if (side === "left") {
        context.moveTo(x, startY)
        context.lineTo(x, height - size + clipDepth)
        context.bezierCurveTo(x, y1 + clipDepth, root.bodyLeft - control, y1 + clipDepth, 0, y1 + clipDepth)
      } else {
        context.moveTo(x, startY)
        context.lineTo(x, height - size + clipDepth)
        context.bezierCurveTo(x, y1 + clipDepth, root.bodyRight + control, y1 + clipDepth, width, y1 + clipDepth)
      }
      context.stroke()
    }

    function drawCurve(context, side): void {
      const size = Math.min(root.theme.bar.island.curveSize, height)
      const control = root.theme.bar.island.curveRadius * 0.6
      const clipDepth = root.theme.metrics.borderWidth
      const top = root.edge === "top"

      context.beginPath()
      if (side === "left" && top) {
        context.moveTo(root.bodyLeft, 0)
        context.lineTo(root.bodyLeft, size - clipDepth)
        context.bezierCurveTo(root.bodyLeft, -clipDepth, root.bodyLeft - control, -clipDepth, 0, -clipDepth)
      } else if (side === "right" && top) {
        context.moveTo(root.bodyRight, 0)
        context.lineTo(root.bodyRight, size - clipDepth)
        context.bezierCurveTo(root.bodyRight, -clipDepth, root.bodyRight + control, -clipDepth, width, -clipDepth)
      } else if (side === "left") {
        context.moveTo(root.bodyLeft, height)
        context.lineTo(root.bodyLeft, height - size + clipDepth)
        context.bezierCurveTo(root.bodyLeft, height + clipDepth, root.bodyLeft - control, height + clipDepth, 0, height + clipDepth)
      } else {
        context.moveTo(root.bodyRight, height)
        context.lineTo(root.bodyRight, height - size + clipDepth)
        context.bezierCurveTo(root.bodyRight, height + clipDepth, root.bodyRight + control, height + clipDepth, width, height + clipDepth)
      }
      context.closePath()
      context.fill()
    }

    onPaint: {
      const context = getContext("2d")
      context.clearRect(0, 0, width, height)

      const topLeftStyle = root.cornerStyle(root.edge === "top" ? "screen" : "content", root.leftRole)
      const topRightStyle = root.cornerStyle(root.edge === "top" ? "screen" : "content", root.rightRole)
      const bottomLeftStyle = root.cornerStyle(root.edge === "top" ? "content" : "screen", root.leftRole)
      const bottomRightStyle = root.cornerStyle(root.edge === "top" ? "content" : "screen", root.rightRole)
      const maxRadius = Math.max(0, Math.min(root.theme.bar.island.radius, height / 2, (root.bodyRight - root.bodyLeft) / 2))
      const topLeft = topLeftStyle === "round" ? maxRadius : 0
      const topRight = topRightStyle === "round" ? maxRadius : 0
      const bottomRight = bottomRightStyle === "round" ? maxRadius : 0
      const bottomLeft = bottomLeftStyle === "round" ? maxRadius : 0

      context.fillStyle = root.theme.surfaces.bar
      roundedBody(context, root.bodyLeft, 0, root.bodyRight, height, topLeft, topRight, bottomRight, bottomLeft)
      context.fill()

      context.fillStyle = root.theme.surfaces.bar
      if (root.leftCurve) drawCurve(context, "left")
      if (root.rightCurve) drawCurve(context, "right")

      const borderWidth = root.theme.metrics.borderWidth
      if (borderWidth <= 0) return

      const inset = borderWidth / 2
      const x0 = root.bodyLeft + inset
      const x1 = root.bodyRight - inset
      const y0 = inset
      const y1 = height - inset
      const insetRadius = radius => Math.max(0, radius - inset)
      const tl = insetRadius(topLeft)
      const tr = insetRadius(topRight)
      const br = insetRadius(bottomRight)
      const bl = insetRadius(bottomLeft)
      const topBorder = root.borderEnabled(root.edge === "top" ? "screen" : "content")
      const bottomBorder = root.borderEnabled(root.edge === "top" ? "content" : "screen")
      const leftBorder = root.borderEnabled(root.leftRole)
      const rightBorder = root.borderEnabled(root.rightRole)

      context.strokeStyle = root.theme.palette.border
      context.lineWidth = borderWidth
      context.lineCap = "butt"
      context.lineJoin = "round"

      if (topBorder) strokeLine(
        context,
        root.edge === "top" && root.leftCurve ? root.bodyLeft : x0 + tl,
        y0,
        root.edge === "top" && root.rightCurve ? root.bodyRight : x1 - tr,
        y0
      )
      if (rightBorder) {
        if (root.rightCurve) {
          strokeCurvedSide(context, "right", x1, y0 + tr, y1 - br, y0, y1)
        } else {
          strokeLine(context, x1, y0 + tr, x1, y1 - br)
        }
      }
      if (bottomBorder) strokeLine(
        context,
        root.edge === "bottom" && root.rightCurve ? root.bodyRight : x1 - br,
        y1,
        root.edge === "bottom" && root.leftCurve ? root.bodyLeft : x0 + bl,
        y1
      )
      if (leftBorder) {
        if (root.leftCurve) {
          strokeCurvedSide(context, "left", x0, y0 + tl, y1 - bl, y0, y1)
        } else {
          strokeLine(context, x0, y1 - bl, x0, y0 + tl)
        }
      }

      if (tr > 0 && (topBorder || rightBorder)) {
        strokeCorner(context, x1 - tr, y0, x1, y0, x1, y0 + tr)
      }
      if (br > 0 && (rightBorder || bottomBorder)) {
        strokeCorner(context, x1, y1 - br, x1, y1, x1 - br, y1)
      }
      if (bl > 0 && (bottomBorder || leftBorder)) {
        strokeCorner(context, x0 + bl, y1, x0, y1, x0, y1 - bl)
      }
      if (tl > 0 && (leftBorder || topBorder)) {
        strokeCorner(context, x0, y0 + tl, x0, y0, x0 + tl, y0)
      }
    }
  }
}
