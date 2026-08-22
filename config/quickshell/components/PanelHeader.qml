import QtQuick

Item {
  id: root

  required property var theme
  property string title: ""
  property string subtitle: ""
  property string actionIcon: "󰒓"
  property var action: null

  implicitWidth: parent?.width ?? 0
  implicitHeight: labels.implicitHeight + root.theme.panelHeaderPadding * 2

  Rectangle {
    anchors.fill: parent
    color: root.theme.panelBackground

    Rectangle {
      anchors.fill: parent
      color: root.theme.panelAccent
      opacity: root.theme.panelHeaderAccentOpacity
    }
  }

  Column {
    id: labels

    anchors.left: parent.left
    anchors.right: headerAction.visible ? headerAction.left : parent.right
    anchors.leftMargin: root.theme.panelHeaderPadding
    anchors.rightMargin: headerAction.visible
      ? root.theme.panelSpacing
      : root.theme.panelHeaderPadding
    anchors.verticalCenter: parent.verticalCenter
    spacing: 2

    Text {
      width: parent.width
      text: root.title
      color: root.theme.panelForeground
      font.family: root.theme.panelFont
      font.pixelSize: root.theme.panelFontSize + 1
      font.weight: root.theme.panelFontWeight
      font.styleName: root.theme.fontStyle
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      visible: root.subtitle.length > 0
      text: root.subtitle
      color: root.theme.panelForeground
      opacity: 0.65
      font.family: root.theme.panelFont
      font.pixelSize: root.theme.readoutFontSize
      elide: Text.ElideRight
    }
  }

  Item {
    id: headerAction

    visible: root.action !== null
    width: 24
    height: 24
    anchors.right: parent.right
    anchors.rightMargin: root.theme.panelHeaderPadding
    anchors.verticalCenter: parent.verticalCenter
    activeFocusOnTab: visible && enabled

    Rectangle {
      anchors.fill: parent
      color: "transparent"
      border.color: headerAction.activeFocus || actionMouse.containsMouse
        ? root.theme.panelAccent
        : "transparent"
      border.width: headerAction.activeFocus || actionMouse.containsMouse
        ? root.theme.panelSelectionBorderWidth
        : 0
      radius: root.theme.panelEntryRadius

      Rectangle {
        anchors.fill: parent
        color: root.theme.panelAccent
        opacity: headerAction.activeFocus || actionMouse.containsMouse
          ? root.theme.panelSelectionAccentOpacity
          : 0
        radius: parent.radius
      }
    }

    Text {
      anchors.centerIn: parent
      text: root.actionIcon
      color: root.theme.panelForeground
      font.family: root.theme.panelFont
      font.pixelSize: root.theme.panelFontSize
      font.weight: root.theme.panelFontWeight
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

}
