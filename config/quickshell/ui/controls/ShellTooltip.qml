import QtQuick
import Quickshell

PopupWindow {
  id: root

  required property Item anchorItem
  required property var anchorWindow
  required property string edge
  required property string text
  required property var theme
  property bool requested: false
  property bool ready: false
  property int gap: 5

  color: "transparent"
  grabFocus: false
  mask: Region {}
  visible: ready && text.length > 0
  implicitWidth: label.implicitWidth + 12
  implicitHeight: label.implicitHeight + 8

  onRequestedChanged: {
    if (requested) delay.restart()
    else {
      delay.stop()
      ready = false
    }
  }

  Timer {
    id: delay
    interval: 550
    onTriggered: root.ready = root.requested
  }

  anchor {
    window: root.anchorWindow
    adjustment: PopupAdjustment.Slide
    gravity: Edges.Bottom | Edges.Right

    onAnchoring: {
      let x = root.anchorItem.width / 2 - root.width / 2
      let y = root.anchorItem.height + root.theme.barMarginContent + root.gap

      if (root.edge === "bottom") {
        y = -root.height - root.theme.barMarginContent - root.gap
      } else if (root.edge === "left") {
        x = root.anchorItem.width + root.gap
        y = root.anchorItem.height / 2 - root.height / 2
      } else if (root.edge === "right") {
        x = -root.width - root.gap
        y = root.anchorItem.height / 2 - root.height / 2
      }

      const point = root.anchorWindow.contentItem.mapFromItem(root.anchorItem, x, y)
      anchor.rect.x = point.x
      anchor.rect.y = point.y
    }
  }

  Rectangle {
    anchors.fill: parent
    color: root.theme.tooltipSurface
    border.color: root.theme.border
    border.width: root.theme.borderWidth
    radius: root.theme.tooltipRadius

    Text {
      id: label
      anchors.centerIn: parent
      text: root.text
      color: root.theme.foreground
      font.family: root.theme.uiFontFamily
      font.pixelSize: root.theme.bodyFontSize
    }
  }
}
