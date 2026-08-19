pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  required property var output
  required property var theme

  readonly property bool active: MenuState.requested
    && output.name === MenuState.screenName
  property real reveal: active ? 1 : 0

  visible: active || reveal > 0
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "hyprkarl-quickshell-menu"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: active
    ? WlrKeyboardFocus.Exclusive
    : WlrKeyboardFocus.None

  anchors.top: true
  anchors.bottom: true
  anchors.left: true
  anchors.right: true
  screen: output

  Behavior on reveal {
    NumberAnimation {
      duration: root.theme.panelTransitionDuration
      easing.type: root.active ? Easing.OutCubic : Easing.InCubic
    }
  }

  contentItem {
    focus: root.active

    Keys.onPressed: event => {
      if (!root.active) return

      if (event.key === Qt.Key_Escape || event.key === Qt.Key_Left || event.key === Qt.Key_Backspace) {
        MenuState.back()
      } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
        if (menuList.count > 0) menuList.currentIndex = (menuList.currentIndex + 1) % menuList.count
      } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
        if (menuList.count > 0) menuList.currentIndex = (menuList.currentIndex - 1 + menuList.count) % menuList.count
      } else if (event.key === Qt.Key_Home) {
        menuList.currentIndex = 0
      } else if (event.key === Qt.Key_End) {
        menuList.currentIndex = Math.max(0, menuList.count - 1)
      } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
          || event.key === Qt.Key_Space || event.key === Qt.Key_Right || event.key === Qt.Key_L) {
        if (menuList.currentIndex >= 0) MenuState.activate(menuList.model[menuList.currentIndex])
      } else {
        return
      }
      event.accepted = true
    }
  }

  onActiveChanged: {
    if (active) Qt.callLater(() => menuList.currentIndex = 0)
  }

  Connections {
    target: MenuState

    function onCurrentMenuChanged(): void {
      menuList.currentIndex = 0
    }
  }

  Rectangle {
    anchors.fill: parent
    color: root.theme.menuScrim
    opacity: root.reveal

    MouseArea {
      anchors.fill: parent
      onClicked: MenuState.close()
    }
  }

  Rectangle {
    id: frame

    readonly property real desiredHeight: root.theme.panelPadding * 2
      + header.height
      + root.theme.panelSpacing
      + menuList.count * 42

    anchors.centerIn: parent
    width: Math.min(root.theme.menuWidth, root.width - root.theme.panelPadding * 2)
    height: Math.min(desiredHeight, root.height - root.theme.panelPadding * 2)
    scale: 0.96 + root.reveal * 0.04
    opacity: root.reveal
    color: root.theme.surface
    border.color: root.theme.border
    border.width: root.theme.borderWidth
    radius: root.theme.panelRadius

    MouseArea {
      anchors.fill: parent
    }

    Item {
      id: header

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.leftMargin: root.theme.panelPadding
      anchors.rightMargin: root.theme.panelPadding
      anchors.topMargin: root.theme.panelPadding
      height: 28

      Item {
        id: backButton

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 28
        visible: MenuState.history.length > 1

        Rectangle {
          anchors.fill: parent
          color: root.theme.accent
          opacity: backMouse.containsMouse ? 0.22 : 0.12
          radius: root.theme.radius
        }

        Text {
          anchors.centerIn: parent
          text: "‹"
          color: root.theme.text
          font.family: root.theme.fontUi
          font.pixelSize: root.theme.fontSize + 4
        }

        MouseArea {
          id: backMouse

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: MenuState.back()
        }
      }

      Text {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: MenuState.menus[MenuState.currentMenu]?.title ?? ""
        color: root.theme.text
        font.family: root.theme.fontUi
        font.pixelSize: root.theme.fontSize + 1
        font.weight: root.theme.fontWeight
        font.styleName: root.theme.fontStyle
        horizontalAlignment: Text.AlignHCenter
      }
    }

    ListView {
      id: menuList

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: header.bottom
      anchors.bottom: parent.bottom
      anchors.leftMargin: root.theme.panelPadding
      anchors.rightMargin: root.theme.panelPadding
      anchors.topMargin: root.theme.panelSpacing
      anchors.bottomMargin: root.theme.panelPadding
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: MenuState.entriesFor(MenuState.currentMenu)
      currentIndex: count > 0 ? 0 : -1

      delegate: MenuEntry {
        required property int index
        required property var modelData

        width: menuList.width
        theme: root.theme
        entry: modelData
        selected: ListView.isCurrentItem
        onHovered: menuList.currentIndex = index
        onChosen: MenuState.activate(modelData)
      }
    }
  }
}
