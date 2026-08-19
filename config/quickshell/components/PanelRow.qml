import QtQuick

Item {
  id: root

  required property var theme
  property string icon: ""
  property string title: ""
  property string detail: ""
  property string error: ""
  property bool selected: false
  property bool busy: false
  property var action: null

  activeFocusOnTab: enabled && action !== null
  implicitWidth: parent?.width ?? 0
  implicitHeight: 40 + (error.length > 0 ? 20 : 0)

  Rectangle {
    anchors.fill: parent
    color: root.theme.accent
    opacity: root.activeFocus ? 0.24 : mouse.containsMouse ? 0.16 : root.selected ? 0.10 : 0
    radius: root.theme.radius
  }

  Text {
    id: iconLabel

    anchors.left: parent.left
    anchors.leftMargin: root.theme.controlPadding
    anchors.verticalCenter: rowArea.verticalCenter
    width: 22
    visible: root.icon.length > 0
    text: root.icon
    color: root.selected ? root.theme.accent : root.theme.text
    font.family: root.theme.fontUi
    font.pixelSize: root.theme.fontSize
    horizontalAlignment: Text.AlignHCenter
  }

  Item {
    id: rowArea

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: 40

    Text {
      anchors.left: parent.left
      anchors.leftMargin: root.theme.controlPadding + (root.icon.length > 0 ? 28 : 0)
      anchors.right: detailLabel.left
      anchors.rightMargin: root.theme.controlPadding
      anchors.verticalCenter: parent.verticalCenter
      text: root.title
      color: root.enabled ? root.theme.text : root.theme.border
      font.family: root.theme.fontUi
      font.pixelSize: root.theme.fontSize
      font.weight: root.selected ? root.theme.fontWeight : Font.Normal
      elide: Text.ElideRight
    }

    Text {
      id: detailLabel

      anchors.right: parent.right
      anchors.rightMargin: root.theme.controlPadding
      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(implicitWidth, parent.width * 0.46)
      text: root.busy ? "…" : root.detail
      color: root.selected ? root.theme.accent : root.theme.text
      opacity: root.selected ? 1 : 0.65
      font.family: root.theme.fontMono
      font.pixelSize: root.theme.readoutFontSize
      horizontalAlignment: Text.AlignRight
      elide: Text.ElideRight
    }
  }

  Text {
    anchors.left: parent.left
    anchors.leftMargin: root.theme.controlPadding + (root.icon.length > 0 ? 28 : 0)
    anchors.right: parent.right
    anchors.rightMargin: root.theme.controlPadding
    anchors.bottom: parent.bottom
    height: 20
    visible: root.error.length > 0
    text: root.error
    color: root.theme.error
    font.family: root.theme.fontUi
    font.pixelSize: root.theme.readoutFontSize
    elide: Text.ElideRight
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
