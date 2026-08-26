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
  property bool switchVisible: false
  property bool switchActive: false
  property var switchAppearance: ({})
  property string navigationSection: "main"
  property var action: null
  readonly property bool navigationSelected: root.selected
  readonly property bool current: NavigationState.currentItem === root
  readonly property bool highlighted: root.current || root.selected

  activeFocusOnTab: enabled && action !== null
  implicitWidth: parent?.width ?? 0
  implicitHeight: 40 + (error.length > 0 ? 20 : 0)

  Rectangle {
    anchors.fill: parent
    color: "transparent"
    border.color: root.highlighted ? root.theme.panelAccent : "transparent"
    border.width: root.highlighted ? root.theme.panelSelectionBorderWidth : 0
    radius: root.theme.panelEntryRadius

    Rectangle {
      anchors.fill: parent
      color: root.theme.panelAccent
      opacity: root.current ? root.theme.panelSelectionAccentOpacity : 0
      radius: parent.radius
    }
  }

  Text {
    id: iconLabel

    anchors.left: parent.left
    anchors.leftMargin: root.theme.panelEntryPadding
    anchors.verticalCenter: rowArea.verticalCenter
    width: 22
    visible: root.icon.length > 0
    text: root.icon
    color: root.selected ? root.theme.panelAccent : root.theme.panelForeground
    font.family: root.theme.panelFont
    font.pixelSize: root.theme.panelFontSize
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
      anchors.leftMargin: root.theme.panelEntryPadding + (root.icon.length > 0 ? 28 : 0)
      anchors.right: detailLabel.visible
        ? detailLabel.left
        : switchIndicator.visible ? switchIndicator.left : parent.right
      anchors.rightMargin: root.theme.panelEntryPadding
      anchors.verticalCenter: parent.verticalCenter
      text: root.title
      color: root.enabled ? root.theme.panelForeground : root.theme.panelBorder
      font.family: root.theme.panelFont
      font.pixelSize: root.theme.panelFontSize
      font.weight: root.selected ? root.theme.panelFontWeight : Font.Normal
      elide: Text.ElideRight
    }

    Text {
      id: detailLabel

      anchors.right: switchIndicator.visible ? switchIndicator.left : parent.right
      anchors.rightMargin: root.theme.panelEntryPadding
      anchors.verticalCenter: parent.verticalCenter
      visible: root.busy || root.detail.length > 0
      width: Math.min(implicitWidth, parent.width * 0.46)
      text: root.busy ? "…" : root.detail
      color: root.selected ? root.theme.panelAccent : root.theme.panelForeground
      opacity: root.selected ? 1 : 0.65
      font.family: root.theme.monoFontFamily
      font.pixelSize: root.theme.readoutFontSize
      horizontalAlignment: Text.AlignRight
      elide: Text.ElideRight
    }

    ToggleIndicator {
      id: switchIndicator

      anchors.right: parent.right
      anchors.rightMargin: root.theme.panelEntryPadding
      anchors.verticalCenter: parent.verticalCenter
      visible: root.switchVisible && !root.busy
      active: root.switchActive
      appearance: root.switchAppearance
      surfaceColor: root.theme.panelBackground
      accentColor: root.theme.panelAccent
      outlineColor: root.theme.panelBorder
      foregroundColor: root.theme.panelForeground
      theme: root.theme
    }
  }

  Text {
    anchors.left: parent.left
    anchors.leftMargin: root.theme.panelEntryPadding + (root.icon.length > 0 ? 28 : 0)
    anchors.right: parent.right
    anchors.rightMargin: root.theme.panelEntryPadding
    anchors.bottom: parent.bottom
    height: 20
    visible: root.error.length > 0
    text: root.error
    color: root.theme.urgent
    font.family: root.theme.panelFont
    font.pixelSize: root.theme.readoutFontSize
    elide: Text.ElideRight
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled && root.action !== null
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onPressed: NavigationState.usePointer(root, root.navigationSection)
    onClicked: root.action()
  }

  HoverHandler {
    enabled: root.enabled && root.action !== null
    blocking: false
    onPointChanged: if (hovered) NavigationState.usePointer(root, root.navigationSection)
  }

  Keys.onPressed: event => {
    if (!root.action || (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space)) return
    NavigationState.useKeyboard(root, Qt.ShortcutFocusReason, root.navigationSection)
    root.action()
    event.accepted = true
  }
}
