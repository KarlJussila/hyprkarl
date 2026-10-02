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

    anchors.left: leadingHeaderAction.visible
      ? leadingHeaderAction.right
      : parent.left
    anchors.right: headerAction.visible ? headerAction.left : parent.right
    anchors.leftMargin: leadingHeaderAction.visible
      ? root.theme.panelSpacing
      : root.theme.panelHeaderPadding
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

  PanelHeaderButton {
    id: leadingHeaderAction

    visible: root.leadingAction !== null
    width: 24
    height: 24
    anchors.left: parent.left
    anchors.leftMargin: root.theme.panelHeaderPadding
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
    anchors.rightMargin: root.theme.panelHeaderPadding
    anchors.verticalCenter: parent.verticalCenter
    theme: root.theme
    icon: root.actionIcon
    action: root.action
  }
}
