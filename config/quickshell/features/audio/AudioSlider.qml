import QtQuick

Item {
  id: root

  required property var theme
  property real value: 0
  property real stepSize: 0.05
  signal edited(real value)

  activeFocusOnTab: enabled
  implicitWidth: parent?.width ?? 180
  implicitHeight: 24

  function setFromPosition(x: real): void {
    edited(Math.max(0, Math.min(1, x / track.width)))
  }

  function step(direction: int): void {
    edited(Math.max(0, Math.min(1, value + stepSize * direction)))
  }

  Rectangle {
    id: track

    anchors.left: parent.left
    anchors.right: valueLabel.left
    anchors.rightMargin: root.theme.controlPadding
    anchors.verticalCenter: parent.verticalCenter
    height: 6
    radius: 3
    color: root.theme.border

    Rectangle {
      width: parent.width * Math.max(0, Math.min(1, root.value))
      height: parent.height
      radius: parent.radius
      color: root.theme.accent
    }

    Rectangle {
      x: Math.max(0, Math.min(parent.width - width, parent.width * root.value - width / 2))
      anchors.verticalCenter: parent.verticalCenter
      width: root.activeFocus ? 12 : 10
      height: width
      radius: width / 2
      color: root.theme.text
    }

    MouseArea {
      anchors.fill: parent
      anchors.topMargin: -8
      anchors.bottomMargin: -8
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onPressed: event => root.setFromPosition(event.x)
      onPositionChanged: event => {
        if (pressed) root.setFromPosition(event.x)
      }
    }
  }

  Text {
    id: valueLabel

    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: 38
    text: `${Math.round(root.value * 100)}%`
    color: root.theme.text
    font.family: root.theme.fontMono
    font.pixelSize: root.theme.readoutFontSize
    horizontalAlignment: Text.AlignRight
  }

  Keys.onLeftPressed: event => {
    root.step(-1)
    event.accepted = true
  }
  Keys.onRightPressed: event => {
    root.step(1)
    event.accepted = true
  }
  Keys.onDownPressed: event => {
    root.step(-1)
    event.accepted = true
  }
  Keys.onUpPressed: event => {
    root.step(1)
    event.accepted = true
  }
}
