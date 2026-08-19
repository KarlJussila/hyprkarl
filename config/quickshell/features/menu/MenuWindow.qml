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
      onClicked: MenuState.back()
    }
  }

  Rectangle {
    id: frame

    readonly property real frameInset: root.theme.menuOuterBorderWidth
      + root.theme.menuOuterPadding
    readonly property real desiredHeight: frameInset * 2
      + root.theme.menuInnerBorderWidth * 2
      + root.theme.menuInnerBorderWidth
      + header.height
      + menuList.contentHeight

    anchors.centerIn: parent
    width: Math.min(root.theme.menuWidth, root.width)
    height: Math.min(desiredHeight, root.height)
    opacity: root.reveal
    color: root.theme.menuBackground
    border.color: root.theme.menuBorder
    border.width: root.theme.menuOuterBorderWidth
    radius: root.theme.menuOuterRadius

    MouseArea {
      anchors.fill: parent
    }

    Rectangle {
      id: innerFrame

      anchors.fill: parent
      anchors.margins: frame.frameInset
      color: root.theme.menuBackground
      border.color: root.theme.menuBorder
      border.width: root.theme.menuInnerBorderWidth
      radius: root.theme.menuInnerRadius

      Rectangle {
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: root.theme.menuInnerBorderWidth
        anchors.rightMargin: root.theme.menuInnerBorderWidth
        anchors.topMargin: root.theme.menuInnerBorderWidth
        height: headerLabel.implicitHeight + root.theme.menuHeaderPadding * 2
        color: root.theme.menuBackground
        topLeftRadius: Math.max(0,
          root.theme.menuInnerRadius - root.theme.menuInnerBorderWidth)
        topRightRadius: topLeftRadius
        bottomLeftRadius: 0
        bottomRightRadius: 0

        Rectangle {
          anchors.fill: parent
          color: root.theme.menuAccent
          opacity: root.theme.menuHeaderAccentOpacity
          topLeftRadius: parent.topLeftRadius
          topRightRadius: parent.topRightRadius
          bottomLeftRadius: 0
          bottomRightRadius: 0
        }

        Text {
          id: headerLabel

          anchors.fill: parent
          anchors.margins: root.theme.menuHeaderPadding
          text: MenuState.menus[MenuState.currentMenu]?.title ?? ""
          color: root.theme.menuForeground
          font.family: root.theme.menuFont
          font.pixelSize: root.theme.menuFontSize
          font.weight: root.theme.menuFontWeight
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
        }
      }

      Rectangle {
        id: headerDivider

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        height: root.theme.menuInnerBorderWidth
        color: root.theme.menuBorder
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: headerDivider.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.theme.menuInnerBorderWidth
        anchors.rightMargin: root.theme.menuInnerBorderWidth
        anchors.bottomMargin: root.theme.menuInnerBorderWidth
        color: root.theme.menuBackground

        ListView {
          id: menuList

          anchors.fill: parent
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
  }
}
