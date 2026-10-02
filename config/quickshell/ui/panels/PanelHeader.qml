import QtQuick

Item {
  id: root

  required property var theme
  property string title: ""
  property string subtitle: ""
  property string leadingActionIcon: "󰁍"
  property var leadingAction: null
  property string actionIcon: "󰒓"
  property var action: null

  implicitWidth: parent?.width ?? 0
  implicitHeight: labels.implicitHeight + root.theme.panel.headerPadding * 2

  Rectangle {
    anchors.fill: parent
    color: root.theme.panel.background

    Rectangle {
      anchors.fill: parent
      color: root.theme.panel.accent
      opacity: root.theme.panel.headerAccentOpacity
    }
  }

  Column {
    id: labels

    anchors.left: leadingHeaderAction.visible
      ? leadingHeaderAction.right
      : parent.left
    anchors.right: headerAction.visible ? headerAction.left : parent.right
    anchors.leftMargin: leadingHeaderAction.visible
      ? root.theme.panel.spacing
      : root.theme.panel.headerPadding
    anchors.rightMargin: headerAction.visible
      ? root.theme.panel.spacing
      : root.theme.panel.headerPadding
    anchors.verticalCenter: parent.verticalCenter
    spacing: 2

    Text {
      width: parent.width
      text: root.title
      color: root.theme.panel.foreground
      font.family: root.theme.panel.font
      font.pixelSize: root.theme.panel.fontSize + 1
      font.weight: root.theme.panel.fontWeight
      font.styleName: root.theme.typography.style
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      visible: root.subtitle.length > 0
      text: root.subtitle
      color: root.theme.panel.foreground
      opacity: 0.65
      font.family: root.theme.panel.font
      font.pixelSize: root.theme.typography.readoutSize
      elide: Text.ElideRight
    }
  }

  PanelHeaderButton {
    id: leadingHeaderAction

    visible: root.leadingAction !== null
    width: 24
    height: 24
    anchors.left: parent.left
    anchors.leftMargin: root.theme.panel.headerPadding
    anchors.verticalCenter: parent.verticalCenter
    theme: root.theme
    icon: root.leadingActionIcon
    action: root.leadingAction
  }

  PanelHeaderButton {
    id: headerAction

    visible: root.action !== null
    width: 24
    height: 24
    anchors.right: parent.right
    anchors.rightMargin: root.theme.panel.headerPadding
    anchors.verticalCenter: parent.verticalCenter
    theme: root.theme
    icon: root.actionIcon
    action: root.action
  }
}
