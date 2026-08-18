import QtQuick

Item {
  id: root

  required property var theme
  property string title: ""
  property string subtitle: ""

  implicitWidth: parent?.width ?? 0
  implicitHeight: subtitle.length > 0 ? 43 : 24

  Text {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    text: root.title
    color: root.theme.text
    font.family: root.theme.fontUi
    font.pixelSize: root.theme.fontSize + 1
    font.weight: root.theme.fontWeight
    font.styleName: root.theme.fontStyle
    elide: Text.ElideRight
  }

  Text {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    visible: root.subtitle.length > 0
    text: root.subtitle
    color: root.theme.text
    opacity: 0.65
    font.family: root.theme.fontUi
    font.pixelSize: root.theme.readoutFontSize
    elide: Text.ElideRight
  }
}
