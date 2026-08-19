pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland

Item {
  id: root

  required property string widgetId
  required property var config
  required property string edge
  required property var barWindow
  required property var theme
  required property var systemState
  required property var panelHost

  implicitWidth: workspaceRow.implicitWidth
  implicitHeight: workspaceRow.implicitHeight

  component WorkspaceButton: Item {
    id: workspaceButton

    required property var workspace

    readonly property bool configured: root.config.alwaysShow.indexOf(workspace.id) >= 0
    readonly property bool shown: workspace.id > 0 && (configured
      || (root.config.includeFocused && workspace.focused)
      || (root.config.includeOccupied && workspace.toplevels.values.length > 0))

    visible: shown
    implicitWidth: shown ? content.implicitWidth : 0
    implicitHeight: shown ? content.implicitHeight : 0
    height: root.height

    Row {
      id: content
      anchors.centerIn: parent
      opacity: workspaceButton.workspace.toplevels.values.length > 0 || workspaceButton.workspace.focused ? 1 : 0.55

      Text {
        text: "["
        color: root.theme.accent
        opacity: workspaceButton.workspace.focused ? 1 : 0
        font.family: root.theme.fontMono
        font.pixelSize: root.theme.readoutFontSize
        font.weight: root.theme.fontWeight
        font.styleName: root.theme.fontStyle
      }

      Text {
        text: workspaceButton.workspace.id
        color: workspaceButton.workspace.focused ? root.theme.accent : root.theme.text
        font.family: root.theme.fontMono
        font.pixelSize: root.theme.readoutFontSize
        font.weight: root.theme.fontWeight
        font.styleName: root.theme.fontStyle
      }

      Text {
        text: "]"
        color: root.theme.accent
        opacity: workspaceButton.workspace.focused ? 1 : 0
        font.family: root.theme.fontMono
        font.pixelSize: root.theme.readoutFontSize
        font.weight: root.theme.fontWeight
        font.styleName: root.theme.fontStyle
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: Hyprland.dispatch(`workspace ${workspaceButton.workspace.id}`)
    }
  }

  Row {
    id: workspaceRow
    x: (parent.width - width) / 2
    width: implicitWidth
    height: parent.height

    Repeater {
      model: Hyprland.workspaces
      WorkspaceButton {
        required property var modelData
        workspace: modelData
      }
    }
  }
}
