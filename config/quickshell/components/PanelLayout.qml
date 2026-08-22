import QtQuick

Item {
  id: root

  required property var theme
  property alias title: header.title
  property alias subtitle: header.subtitle
  property alias actionIcon: header.actionIcon
  property alias action: header.action
  default property alias bodyData: body.data

  implicitWidth: parent?.width ?? 0
  implicitHeight: layout.implicitHeight

  Column {
    id: layout

    width: parent.width
    spacing: 0

    PanelHeader {
      id: header

      width: parent.width
      theme: root.theme
    }

    Rectangle {
      width: parent.width
      height: root.theme.panelInnerBorderWidth
      color: root.theme.panelBorder
    }

    Item {
      width: parent.width
      implicitHeight: body.implicitHeight
        + root.theme.panelPadding * 2
        + root.theme.panelOuterPadding

      Column {
        id: body

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.theme.panelPadding
        spacing: root.theme.panelSpacing
      }
    }
  }
}
