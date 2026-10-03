pragma ComponentBehavior: Bound

import QtQuick
import "../../ui/modal"

PickerWindow {
  id: root

  readonly property bool active: MenuState.requested
    && output.name === MenuState.screenName
  readonly property string widthRole:
    MenuState.menus[MenuState.currentMenu]?.widthRole ?? "default"
  readonly property real baseWidth: widthRole === "reference"
    ? theme.menu.referenceWidth
    : widthRole === "search"
      ? theme.menu.searchWidth
      : theme.menu.width
  readonly property string entryAlignment:
    MenuState.menus[MenuState.currentMenu]?.entryAlignment ?? "center"
  readonly property bool searching: query.trim().length > 0
  readonly property int entryTextAlignment: entryAlignment === "left"
    ? Text.AlignLeft
    : entryAlignment === "right"
      ? Text.AlignRight
      : Text.AlignHCenter
  readonly property real rowHeight: emptyLabel.implicitHeight
    + theme.menu.entryPadding * 2
    + theme.menu.entryMargin * 2
  readonly property real bodyHeight: menuList.count > 0
    ? searching
      ? Math.min(menuList.contentHeight, rowHeight * theme.menu.searchRows)
      : menuList.contentHeight
    : rowHeight
  property bool pointerPositionKnown: false
  property point pointerPosition: Qt.point(0, 0)
  property bool restoringView: false
  property bool selectionVisible: true

  shown: active
  title: MenuState.menus[MenuState.currentMenu]?.title ?? ""
  placeholder: "Search…"
  searchPinned: widthRole !== "default"
  clearQueryOnShow: false
  requestedWidth: baseWidth
  requestedBodyHeight: bodyHeight

  function selectableIndex(index, direction): int {
    if (menuList.count === 0) return -1

    const step = direction < 0 ? -1 : 1
    let nextIndex = (index + menuList.count) % menuList.count
    for (let count = 0; count < menuList.count; count++) {
      if (menuList.model[nextIndex].disabled !== true) return nextIndex
      nextIndex = (nextIndex + step + menuList.count) % menuList.count
    }
    return -1
  }

  function selectIndex(index, direction): void {
    const nextIndex = selectableIndex(index, direction)
    menuList.currentIndex = nextIndex
    if (nextIndex >= 0) menuList.positionViewAtIndex(nextIndex, ListView.Contain)
  }

  function moveSelection(offset): void {
    if (menuList.count === 0) return
    selectIndex(menuList.currentIndex < 0
      ? (offset > 0 ? 0 : menuList.count - 1)
      : menuList.currentIndex + offset, offset)
    selectionVisible = menuList.currentIndex >= 0
  }

  function resetSelection(): void {
    momentum.reset()
    pointerPositionKnown = false
    selectIndex(0, 1)
    selectionVisible = menuList.currentIndex >= 0
    if (menuList.count > 0) menuList.positionViewAtBeginning()
  }

  function saveView(): void {
    const selectedEntry = selectionVisible && menuList.currentIndex >= 0
      ? menuList.model[menuList.currentIndex].id
      : ""
    MenuState.rememberView(query, selectedEntry, menuList.contentY)
  }

  function scheduleViewRestore(): void {
    pointerPositionKnown = false
    restoringView = true
    Qt.callLater(restoreView)
  }

  function restoreView(): void {
    const view = MenuState.currentView()
    query = view?.query ?? ""
    Qt.callLater(() => applyView(view))
  }

  function applyView(view): void {
    momentum.reset()
    let selectedIndex = -1
    if (view) {
      for (let index = 0; index < menuList.count; index++) {
        if (menuList.model[index].id === view.selectedEntry) {
          selectedIndex = index
          break
        }
      }
    }

    if (selectedIndex < 0) {
      resetSelection()
    } else {
      menuList.currentIndex = selectedIndex
      selectionVisible = true
      const minimum = menuList.originY
      const maximum = minimum + Math.max(0,
        menuList.contentHeight - menuList.height)
      menuList.contentY = Math.max(minimum,
        Math.min(maximum, view.contentY))
    }
    resetInput()
    restoringView = false
  }

  function activate(entry): void {
    saveView()
    MenuState.activate(entry)
  }

  function selectFromPointer(index, sceneX, sceneY): void {
    const moved = pointerPositionKnown
      && (sceneX !== pointerPosition.x || sceneY !== pointerPosition.y)

    pointerPosition = Qt.point(sceneX, sceneY)
    pointerPositionKnown = true
    if (moved && menuList.model[index].disabled !== true) {
      menuList.currentIndex = index
      selectionVisible = true
    }
  }

  function handleKey(event, editing): void {
    if (event.key === Qt.Key_Escape
        || (event.key === Qt.Key_Q && event.modifiers === Qt.NoModifier)) {
      MenuState.close()
    } else if (event.key === Qt.Key_Down) {
      moveSelection(1)
    } else if (event.key === Qt.Key_Up) {
      moveSelection(-1)
    } else if (event.key === Qt.Key_Home) {
      selectIndex(0, 1)
      selectionVisible = menuList.currentIndex >= 0
    } else if (event.key === Qt.Key_End) {
      selectIndex(menuList.count - 1, -1)
      selectionVisible = menuList.currentIndex >= 0
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
        || (query.length === 0 && event.key === Qt.Key_Right)) {
      if (menuList.currentIndex >= 0) {
        activate(menuList.model[menuList.currentIndex])
      }
    } else if (query.length === 0 && event.key === Qt.Key_Left) {
      saveView()
      MenuState.back()
    } else if (!editing && !searchShown && event.text.length > 0
        && (event.modifiers & (Qt.ControlModifier | Qt.AltModifier
          | Qt.MetaModifier)) === 0) {
      query = event.text
      Qt.callLater(() => focusSearch())
    } else {
      return
    }
    event.accepted = true
  }

  onOutsideClicked: MenuState.close()
  onKeyPressed: (event, editing) => handleKey(event, editing)
  onQueryChanged: if (!restoringView) Qt.callLater(resetSelection)
  onActiveChanged: if (active) scheduleViewRestore()

  Connections {
    target: MenuState

    function onCurrentMenuChanged(): void {
      if (root.active) root.scheduleViewRestore()
    }
  }

  Rectangle {
    anchors.fill: parent
    color: root.theme.menu.background

    Text {
      id: emptyLabel

      anchors.fill: parent
      anchors.margins: root.theme.menu.entryPadding
      visible: menuList.count === 0
      text: MenuState.menuMessage(MenuState.currentMenu, root.query)
      color: root.theme.menu.foreground
      opacity: 0.7
      font.family: root.theme.menu.font
      font.pixelSize: root.theme.menu.fontSize
      font.weight: root.theme.menu.fontWeight
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
      onCountChanged: if (!root.restoringView) Qt.callLater(root.resetSelection)

      section.property: "searchSection"
      section.criteria: ViewSection.FullString
      section.delegate: Item {
        required property string section

        width: ListView.view.width
        height: section === "descendant" ? root.theme.menu.entryMargin * 2 + 1 : 0
        visible: section === "descendant"

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          height: 1
          color: root.theme.menu.border
        }
      }

      delegate: MenuEntry {
        required property int index
        required property var modelData

        width: menuList.width
        theme: root.theme
        entry: modelData
        textAlignment: root.entryTextAlignment
        refreshToken: MenuState.openRevision
        selected: root.selectionVisible && ListView.isCurrentItem
        onPointerMoved: (sceneX, sceneY) =>
          root.selectFromPointer(index, sceneX, sceneY)
        onChosen: if (modelData.disabled !== true) root.activate(modelData)
      }
    }
  }

  MomentumScroll {
    id: momentum
    flickable: menuList
  }
}
