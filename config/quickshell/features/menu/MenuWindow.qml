pragma ComponentBehavior: Bound

import QtQuick
import "../overlay"

OverlayWindow {
  id: root

  readonly property bool active: MenuState.requested
    && output.name === MenuState.screenName
  readonly property string widthRole:
    MenuState.menus[MenuState.currentMenu]?.widthRole ?? "default"
  readonly property string entryAlignment:
    MenuState.menus[MenuState.currentMenu]?.entryAlignment ?? "center"
  readonly property int entryTextAlignment: entryAlignment === "left"
    ? Text.AlignLeft
    : entryAlignment === "right"
      ? Text.AlignRight
      : Text.AlignHCenter
  readonly property real rowHeight: emptyLabel.implicitHeight
    + theme.menuEntryPadding * 2
    + theme.menuEntryMargin * 2
  readonly property real bodyHeight: searchable
    ? rowHeight * theme.menuSearchRows
    : menuList.count > 0
      ? menuList.contentHeight
      : rowHeight
  property bool pointerPositionKnown: false
  property point pointerPosition: Qt.point(0, 0)

  shown: active
  title: MenuState.menus[MenuState.currentMenu]?.title ?? ""
  placeholder: "Search…"
  searchable: MenuState.menus[MenuState.currentMenu]?.searchable === true
  requestedWidth: widthRole === "reference"
    ? theme.menuReferenceWidth
    : widthRole === "search"
      ? theme.menuSearchWidth
      : theme.menuWidth
  requestedBodyHeight: bodyHeight

  function selectIndex(index): void {
    if (menuList.count === 0) {
      menuList.currentIndex = -1
      return
    }

    const nextIndex = (index + menuList.count) % menuList.count
    menuList.currentIndex = nextIndex
    menuList.positionViewAtIndex(nextIndex, ListView.Contain)
  }

  function moveSelection(offset): void {
    if (menuList.count === 0) return
    selectIndex(menuList.currentIndex < 0
      ? (offset > 0 ? 0 : menuList.count - 1)
      : menuList.currentIndex + offset)
  }

  function resetSelection(): void {
    momentum.reset()
    menuList.currentIndex = menuList.count > 0 ? 0 : -1
    if (menuList.count > 0) menuList.positionViewAtBeginning()
  }

  function selectFromPointer(index, sceneX, sceneY): void {
    const moved = pointerPositionKnown
      && (sceneX !== pointerPosition.x || sceneY !== pointerPosition.y)

    pointerPosition = Qt.point(sceneX, sceneY)
    pointerPositionKnown = true
    if (moved) menuList.currentIndex = index
  }

  function handleKey(event, editing): void {
    if (event.key === Qt.Key_Escape) {
      if (editing && query.length > 0) query = ""
      else MenuState.back()
    } else if (event.key === Qt.Key_Down
        || (!editing && event.key === Qt.Key_J)) {
      moveSelection(1)
    } else if (event.key === Qt.Key_Up
        || (!editing && event.key === Qt.Key_K)) {
      moveSelection(-1)
    } else if (!editing && event.key === Qt.Key_Home) {
      selectIndex(0)
    } else if (!editing && event.key === Qt.Key_End) {
      selectIndex(menuList.count - 1)
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
        || (!editing && (event.key === Qt.Key_Space
          || event.key === Qt.Key_Right || event.key === Qt.Key_L))) {
      if (menuList.currentIndex >= 0) {
        MenuState.activate(menuList.model[menuList.currentIndex])
      }
    } else if (!editing
        && (event.key === Qt.Key_Left || event.key === Qt.Key_Backspace)) {
      MenuState.back()
    } else {
      return
    }
    event.accepted = true
  }

  onOutsideClicked: MenuState.back()
  onKeyPressed: (event, editing) => handleKey(event, editing)
  onQueryChanged: Qt.callLater(resetSelection)
  onActiveChanged: if (active) Qt.callLater(resetSelection)

  Connections {
    target: MenuState

    function onCurrentMenuChanged(): void {
      root.query = ""
      Qt.callLater(root.resetSelection)
      if (root.active) Qt.callLater(root.resetInput)
    }
  }

  Rectangle {
    anchors.fill: parent
    color: root.theme.menuBackground

    Text {
      id: emptyLabel

      anchors.fill: parent
      anchors.margins: root.theme.menuEntryPadding
      visible: menuList.count === 0
      text: MenuState.menuMessage(MenuState.currentMenu, root.query)
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
      maximumFlickVelocity: 5000
      highlightFollowsCurrentItem: false
      model: MenuState.entriesFor(MenuState.currentMenu, root.query)
      currentIndex: -1
      onCountChanged: Qt.callLater(root.resetSelection)

      delegate: MenuEntry {
        required property int index
        required property var modelData

        width: menuList.width
        theme: root.theme
        entry: modelData
        textAlignment: root.entryTextAlignment
        refreshToken: MenuState.openRevision
        selected: ListView.isCurrentItem
        onPointerMoved: (sceneX, sceneY) =>
          root.selectFromPointer(index, sceneX, sceneY)
        onChosen: MenuState.activate(modelData)
      }
    }
  }

  MomentumScroll {
    id: momentum
    flickable: menuList
  }
}
