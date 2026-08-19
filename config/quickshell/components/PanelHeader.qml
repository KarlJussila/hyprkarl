import QtQuick

Item {
  id: root

  required property var theme
  property string title: ""
  property string subtitle: ""
  property string actionIcon: "󰒓"
  property var action: null

  implicitWidth: parent?.width ?? 0
  implicitHeight: subtitle.length > 0 ? 43 : 24

  Text {
    anchors.left: parent.left
    anchors.right: headerAction.visible ? headerAction.left : parent.right
    anchors.rightMargin: headerAction.visible ? root.theme.panelSpacing : 0
    anchors.top: parent.top
    text: root.title
    color: root.theme.text
    font.family: root.theme.fontUi
    font.pixelSize: root.theme.fontSize + 1
    font.weight: root.theme.fontWeight
    font.styleName: root.theme.fontStyle
    elide: Text.ElideRight
  }

  Item {
    id: headerAction

    visible: root.action !== null
    width: 24
    height: 24
    anchors.right: parent.right
    anchors.top: parent.top
    activeFocusOnTab: visible && enabled

    Rectangle {
      anchors.fill: parent
      color: root.theme.accent
      opacity: headerAction.activeFocus ? 0.30 : actionMouse.containsMouse ? 0.22 : 0.14
      radius: root.theme.radius
    }

    Text {
      anchors.centerIn: parent
      text: root.actionIcon
      color: root.theme.text
      font.family: root.theme.fontUi
      font.pixelSize: root.theme.fontSize
      font.weight: root.theme.fontWeight
    }

    MouseArea {
      id: actionMouse

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.action()
    }

    Keys.onPressed: event => {
      if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space) return
      root.action()
      event.accepted = true
    }
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
