import QtQuick

Item {
  id: root

  required property string icon
  required property string text
  required property bool expanded
  required property var theme
  property int gap: 4

  implicitWidth: iconLabel.implicitWidth + reveal.width
  implicitHeight: Math.max(iconLabel.implicitHeight, reveal.implicitHeight)

  Text {
    id: iconLabel

    anchors.left: parent.left
    anchors.top: parent.top
    text: root.icon
    color: root.theme.palette.foreground
    font.family: root.theme.typography.uiFamily
    font.pixelSize: root.theme.typography.bodySize
    font.weight: root.theme.typography.weight
    font.styleName: root.theme.typography.style
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  Item {
    id: reveal

    x: iconLabel.width
    y: 0
    width: root.expanded ? valueLabel.implicitWidth + root.gap : 0
    height: implicitHeight
    implicitWidth: valueLabel.implicitWidth
    implicitHeight: valueLabel.implicitHeight
    clip: true

    Behavior on width {
      NumberAnimation {
        duration: 200
        easing.type: root.expanded ? Easing.OutCubic : Easing.InCubic
      }
    }

    Text {
      id: valueLabel

      x: root.gap
      y: 0
      text: root.text
      color: root.theme.palette.foreground
      font.family: root.theme.typography.monoFamily
      font.pixelSize: root.theme.typography.readoutSize
      font.weight: root.theme.typography.weight
      font.styleName: root.theme.typography.style
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }
  }
}
