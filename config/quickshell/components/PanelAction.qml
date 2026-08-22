import QtQuick

Item {
  id: root

  required property var theme
  property string text: ""
  property string icon: ""
  property var action: null
  readonly property bool highlighted: root.activeFocus || mouse.containsMouse

  activeFocusOnTab: enabled && action !== null
  implicitWidth: parent?.width ?? label.implicitWidth + root.theme.panelEntryPadding * 2
  implicitHeight: 34

  Rectangle {
    anchors.fill: parent
    color: root.theme.panelBackground
    border.color: root.highlighted ? root.theme.panelAccent : root.theme.panelBorder
    border.width: root.theme.panelSelectionBorderWidth
    radius: root.theme.panelEntryRadius

    Rectangle {
      anchors.fill: parent
      color: root.theme.panelAccent
      opacity: root.highlighted ? root.theme.panelSelectionAccentOpacity : 0
      radius: parent.radius
    }
  }

  Text {
    id: label

    anchors.centerIn: parent
    text: root.icon.length > 0 ? `${root.icon}  ${root.text}` : root.text
    color: root.theme.panelForeground
    font.family: root.theme.panelFont
    font.pixelSize: root.theme.panelFontSize
    font.weight: root.theme.panelFontWeight
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
