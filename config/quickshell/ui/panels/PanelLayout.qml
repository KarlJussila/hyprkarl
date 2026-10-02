import QtQuick

Item {
  id: root

  required property var theme
  property alias title: header.title
  property alias subtitle: header.subtitle
  property alias leadingActionIcon: header.leadingActionIcon
  property alias leadingAction: header.leadingAction
  property alias actionIcon: header.actionIcon
  property alias action: header.action
  default property alias bodyData: body.data
  readonly property rect navigationSectionBounds: Qt.rect(
    0,
    bodyContainer.y,
    width,
    bodyContainer.height
  )
  readonly property rect navigationContentBounds: Qt.rect(
    body.x,
    bodyContainer.y + body.y,
    body.width,
    body.implicitHeight
  )

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
      height: root.theme.panel.innerBorderWidth
      color: root.theme.panel.border
    }

    Item {
      id: bodyContainer

      width: parent.width
      implicitHeight: body.implicitHeight
        + root.theme.panel.padding * 2
        + root.theme.panel.outerPadding

      Column {
        id: body

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.theme.panel.padding
        spacing: root.theme.panel.spacing
      }
    }
  }
}
