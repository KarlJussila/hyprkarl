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
  readonly property bool searchable: MenuState.menus[MenuState.currentMenu]?.searchable === true
  readonly property string widthRole: MenuState.menus[MenuState.currentMenu]?.widthRole ?? "default"
  readonly property real requestedWidth: widthRole === "reference"
    ? theme.menuReferenceWidth
    : widthRole === "search"
      ? theme.menuSearchWidth
      : theme.menuWidth
  property real reveal: active ? 1 : 0

  function handleKey(event, editing): void {
    if (event.key === Qt.Key_Escape) {
      if (editing && searchInput.text.length > 0) searchInput.clear()
      else MenuState.back()
    } else if (event.key === Qt.Key_Down || (!editing && event.key === Qt.Key_J)) {
      if (menuList.count > 0) menuList.currentIndex = (menuList.currentIndex + 1) % menuList.count
    } else if (event.key === Qt.Key_Up || (!editing && event.key === Qt.Key_K)) {
      if (menuList.count > 0) menuList.currentIndex = (menuList.currentIndex - 1 + menuList.count) % menuList.count
    } else if (!editing && event.key === Qt.Key_Home) {
      menuList.currentIndex = 0
    } else if (!editing && event.key === Qt.Key_End) {
      menuList.currentIndex = Math.max(0, menuList.count - 1)
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
        || (!editing && (event.key === Qt.Key_Space || event.key === Qt.Key_Right || event.key === Qt.Key_L))) {
      if (menuList.currentIndex >= 0) MenuState.activate(menuList.model[menuList.currentIndex])
    } else if (!editing && (event.key === Qt.Key_Left || event.key === Qt.Key_Backspace)) {
      MenuState.back()
    } else {
      return
    }
    event.accepted = true
  }

  function resetMenuFocus(): void {
    searchInput.clear()
    menuList.currentIndex = menuList.count > 0 ? 0 : -1
    if (root.searchable) searchInput.forceActiveFocus()
    else root.contentItem.forceActiveFocus()
  }

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

    Keys.onPressed: event => root.handleKey(event, false)
  }

  onActiveChanged: {
    if (active) Qt.callLater(root.resetMenuFocus)
  }

  Connections {
    target: MenuState

    function onCurrentMenuChanged(): void {
      Qt.callLater(root.resetMenuFocus)
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
    readonly property real rowHeight: emptyLabel.implicitHeight
        + root.theme.menuEntryPadding * 2
        + root.theme.menuEntryMargin * 2
    readonly property real bodyHeight: root.searchable
      ? rowHeight * root.theme.menuSearchRows
      : menuList.count > 0
        ? menuList.contentHeight
        : rowHeight
    readonly property real desiredHeight: frameInset * 2
      + root.theme.menuInnerBorderWidth * 2
      + root.theme.menuInnerBorderWidth
      + header.height
      + searchArea.height
      + searchDivider.height
      + bodyHeight

    anchors.centerIn: parent
    width: Math.min(root.requestedWidth, root.width)
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
        id: searchArea

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: headerDivider.bottom
        anchors.leftMargin: root.theme.menuInnerBorderWidth
        anchors.rightMargin: root.theme.menuInnerBorderWidth
        visible: root.searchable
        height: visible
          ? searchInput.implicitHeight
            + root.theme.menuEntryPadding * 2
            + root.theme.menuEntryMargin * 2
          : 0
        color: root.theme.menuBackground

        Rectangle {
          anchors.fill: parent
          anchors.margins: root.theme.menuEntryMargin
          color: root.theme.menuBackground
          border.color: searchInput.activeFocus
            ? root.theme.menuAccent
            : root.theme.menuBorder
          border.width: root.theme.menuSelectionBorderWidth
          radius: root.theme.menuEntryRadius

          Text {
            anchors.fill: parent
            anchors.margins: root.theme.menuEntryPadding
            visible: searchInput.text.length === 0
            text: "Search…"
            color: root.theme.menuForeground
            opacity: 0.55
            font.family: root.theme.menuFont
            font.pixelSize: root.theme.menuFontSize
            font.weight: root.theme.menuFontWeight
            verticalAlignment: Text.AlignVCenter
          }

          TextInput {
            id: searchInput

            anchors.fill: parent
            anchors.margins: root.theme.menuEntryPadding
            color: root.theme.menuForeground
            selectionColor: root.theme.menuAccent
            selectedTextColor: root.theme.menuBackground
            font.family: root.theme.menuFont
            font.pixelSize: root.theme.menuFontSize
            font.weight: root.theme.menuFontWeight
            verticalAlignment: TextInput.AlignVCenter
            selectByMouse: true
            clip: true
            onTextChanged: menuList.currentIndex = menuList.count > 0 ? 0 : -1
            Keys.onPressed: event => root.handleKey(event, true)
          }
        }
      }

      Rectangle {
        id: searchDivider

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: searchArea.bottom
        visible: root.searchable
        height: visible ? root.theme.menuInnerBorderWidth : 0
        color: root.theme.menuBorder
      }

      Rectangle {
        id: body

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: searchDivider.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.theme.menuInnerBorderWidth
        anchors.rightMargin: root.theme.menuInnerBorderWidth
        anchors.bottomMargin: root.theme.menuInnerBorderWidth
        color: root.theme.menuBackground

        Text {
          id: emptyLabel

          anchors.fill: parent
          anchors.margins: root.theme.menuEntryPadding
          visible: menuList.count === 0
          text: MenuState.menuMessage(MenuState.currentMenu, searchInput.text)
          color: root.theme.menuForeground
          opacity: 0.7
          font.family: root.theme.menuFont
          font.pixelSize: root.theme.menuFontSize
          font.weight: root.theme.menuFontWeight
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
        }

        ListView {
          id: menuList

          anchors.fill: parent
          visible: count > 0
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          model: MenuState.entriesFor(MenuState.currentMenu, searchInput.text)
          currentIndex: count > 0 ? 0 : -1
          onCountChanged: {
            if (count > 0 && currentIndex < 0) currentIndex = 0
          }

          delegate: MenuEntry {
            required property int index
            required property var modelData

            width: menuList.width
            theme: root.theme
            entry: modelData
            refreshToken: MenuState.openRevision
            selected: ListView.isCurrentItem
            onHovered: menuList.currentIndex = index
            onChosen: MenuState.activate(modelData)
          }
        }
      }
    }
  }
}
