import QtQuick

Item {
  id: root

  required property var theme
  property string text: ""
  property string icon: ""
  property var action: null

  activeFocusOnTab: enabled && action !== null
  implicitWidth: parent?.width ?? label.implicitWidth + root.theme.widgetPadding * 2
  implicitHeight: 34

  Rectangle {
    anchors.fill: parent
    color: root.theme.accent
    opacity: root.activeFocus ? 0.30 : mouse.containsMouse ? 0.22 : 0.14
    radius: root.theme.radius
  }

  Text {
    id: label

    anchors.centerIn: parent
    text: root.icon.length > 0 ? `${root.icon}  ${root.text}` : root.text
    color: root.theme.text
    font.family: root.theme.fontUi
    font.pixelSize: root.theme.fontSize
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
