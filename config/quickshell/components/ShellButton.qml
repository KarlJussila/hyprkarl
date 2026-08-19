import QtQuick
import Quickshell

Item {
  id: root

  property string text: ""
  property string tooltip: ""
  property bool tooltipSuppressed: false
  property string primaryCommand: ""
  property string secondaryCommand: ""
  property string tertiaryCommand: ""
  property var onPrimary: null
  property var onSecondary: null
  property var onTertiary: null
  property Component contentComponent: null
  required property var theme
  required property string edge
  required property var barWindow
  required property var panelHost
  property color textColor: theme.text
  readonly property bool hovered: mouse.containsMouse

  readonly property real contentWidth: contentComponent ? contentLoader.implicitWidth : label.implicitWidth
  readonly property real contentHeight: contentComponent ? contentLoader.implicitHeight : label.implicitHeight

  implicitWidth: contentWidth + theme.widgetPadding * 2
  implicitHeight: contentHeight + theme.widgetVerticalPadding * 2

  Text {
    id: label
    anchors.centerIn: parent
    text: root.text
    color: root.textColor
    font.family: root.theme.fontUi
    font.pixelSize: root.theme.fontSize
    font.weight: root.theme.fontWeight
    font.styleName: root.theme.fontStyle
    textFormat: Text.PlainText
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    visible: !root.contentComponent
  }

  Loader {
    id: contentLoader
    anchors.centerIn: parent
    sourceComponent: root.contentComponent
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: event => {
      if (event.button === Qt.LeftButton) {
        if (root.onPrimary) root.onPrimary()
        else if (root.primaryCommand) Quickshell.execDetached(["bash", "-lc", root.primaryCommand])
      } else if (event.button === Qt.RightButton) {
        if (root.onSecondary) root.onSecondary()
        else if (root.secondaryCommand) Quickshell.execDetached(["bash", "-lc", root.secondaryCommand])
      } else if (event.button === Qt.MiddleButton) {
        if (root.onTertiary) root.onTertiary()
        else if (root.tertiaryCommand) Quickshell.execDetached(["bash", "-lc", root.tertiaryCommand])
      }
    }

  }

  ShellTooltip {
    anchorItem: root
    anchorWindow: root.barWindow
    edge: root.edge
    text: root.tooltip
    theme: root.theme
    requested: mouse.containsMouse && !root.tooltipSuppressed && root.tooltip.length > 0
  }
}
