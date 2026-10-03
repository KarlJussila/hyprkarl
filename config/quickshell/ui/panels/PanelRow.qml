import QtQuick
import "../controls"
import "../navigation"

NavigationControl {
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
  readonly property bool navigationSelected: root.selected
  readonly property bool highlighted: root.current || root.selected

  implicitWidth: parent?.width ?? 0
  implicitHeight: 40 + (error.length > 0 ? 20 : 0)

  Rectangle {
    anchors.fill: parent
    color: "transparent"
    border.color: root.highlighted ? root.theme.panel.accent : "transparent"
    border.width: root.highlighted ? root.theme.panel.selectionBorderWidth : 0
    radius: root.theme.panel.entryRadius

    Rectangle {
      anchors.fill: parent
      color: root.theme.panel.accent
      opacity: root.current ? root.theme.panel.selectionAccentOpacity : 0
      radius: parent.radius
    }
  }

  Text {
    id: iconLabel

    anchors.left: parent.left
    anchors.leftMargin: root.theme.panel.entryPadding
    anchors.verticalCenter: rowArea.verticalCenter
    width: 22
    visible: root.icon.length > 0
    text: root.icon
    color: root.selected ? root.theme.panel.accent : root.theme.panel.foreground
    font.family: root.theme.panel.font
    font.pixelSize: root.theme.panel.fontSize
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
      anchors.leftMargin: root.theme.panel.entryPadding + (root.icon.length > 0 ? 28 : 0)
      anchors.right: detailLabel.visible
        ? detailLabel.left
        : switchIndicator.visible ? switchIndicator.left : parent.right
      anchors.rightMargin: root.theme.panel.entryPadding
      anchors.verticalCenter: parent.verticalCenter
      text: root.title
      color: root.enabled ? root.theme.panel.foreground : root.theme.panel.border
      font.family: root.theme.panel.font
      font.pixelSize: root.theme.panel.fontSize
      font.weight: root.selected ? root.theme.panel.fontWeight : Font.Normal
      elide: Text.ElideRight
    }

    Text {
      id: detailLabel

      anchors.right: switchIndicator.visible ? switchIndicator.left : parent.right
      anchors.rightMargin: root.theme.panel.entryPadding
      anchors.verticalCenter: parent.verticalCenter
      visible: root.busy || root.detail.length > 0
      width: Math.min(implicitWidth, parent.width * 0.46)
      text: root.busy ? "…" : root.detail
      color: root.selected ? root.theme.panel.accent : root.theme.panel.foreground
      opacity: root.selected ? 1 : 0.65
      font.family: root.theme.typography.monoFamily
      font.pixelSize: root.theme.typography.readoutSize
      horizontalAlignment: Text.AlignRight
      elide: Text.ElideRight
    }

    ToggleIndicator {
      id: switchIndicator

      anchors.right: parent.right
      anchors.rightMargin: root.theme.panel.entryPadding
      anchors.verticalCenter: parent.verticalCenter
      visible: root.switchVisible && !root.busy
      active: root.switchActive
      appearance: root.switchAppearance
      surfaceColor: root.theme.panel.background
      accentColor: root.theme.panel.accent
      outlineColor: root.theme.panel.border
      foregroundColor: root.theme.panel.foreground
      theme: root.theme
    }
  }

  Text {
    anchors.left: parent.left
    anchors.leftMargin: root.theme.panel.entryPadding + (root.icon.length > 0 ? 28 : 0)
    anchors.right: parent.right
    anchors.rightMargin: root.theme.panel.entryPadding
    anchors.bottom: parent.bottom
    height: 20
    visible: root.error.length > 0
    text: root.error
    color: root.theme.palette.urgent
    font.family: root.theme.panel.font
    font.pixelSize: root.theme.typography.readoutSize
    elide: Text.ElideRight
  }
}
