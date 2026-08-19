import QtQuick

Item {
  id: root

  required property var theme
  property string text: ""
  property var action: null

  activeFocusOnTab: enabled && action !== null
  implicitWidth: 34
  implicitHeight: 34

  Rectangle {
    anchors.fill: parent
    color: root.theme.accent
    opacity: root.activeFocus ? 0.30 : mouse.containsMouse ? 0.22 : 0.10
    radius: root.theme.controlRadius
  }

  Text {
    anchors.centerIn: parent
    text: root.text
    color: root.theme.foreground
    font.family: root.theme.uiFontFamily
    font.pixelSize: root.theme.bodyFontSize
    font.weight: root.theme.fontWeight
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled && root.action !== null
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.action()
  }

  Keys.onPressed: event => {
    if (!root.action || (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space)) return
    root.action()
    event.accepted = true
  }
}
