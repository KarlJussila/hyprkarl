pragma ComponentBehavior: Bound

import QtQuick
import "../overlay"

OverlayWindow {
  id: root

  readonly property bool active: WallpaperPickerState.active
    && output.name === OverlayState.screenName
  readonly property int columns: theme.wallpaperPickerColumns
  readonly property real thumbnailSize: Math.floor(
    height * theme.wallpaperThumbnailScreenFraction)
  readonly property real cellGap: theme.wallpaperPickerGap
  property bool pointerPositionKnown: false
  property point pointerPosition: Qt.point(0, 0)

  shown: active
  title: WallpaperPickerState.action === "remove"
    ? "Remove Wallpaper"
    : "Wallpapers"
  searchable: false
  requestedWidth: thumbnailSize * columns + cellGap * (columns + 1)
  requestedBodyHeight: thumbnailSize + cellGap * 2

  function resetSelection(): void {
    momentum.reset()
    let index = WallpaperPickerState.entries.findIndex(entry => entry.current)
    if (index < 0 && wallpaperGrid.count > 0) index = 0
    wallpaperGrid.currentIndex = index
    if (index >= 0) wallpaperGrid.positionViewAtIndex(index, GridView.Contain)
  }

  function selectIndex(index): void {
    if (wallpaperGrid.count === 0) return
    const next = (index + wallpaperGrid.count) % wallpaperGrid.count
    wallpaperGrid.currentIndex = next
    wallpaperGrid.positionViewAtIndex(next, GridView.Contain)
  }

  function handleKey(event): void {
    if (event.key === Qt.Key_Escape) {
      WallpaperPickerState.close()
    } else if (event.key === Qt.Key_Right) {
      selectIndex(wallpaperGrid.currentIndex + 1)
    } else if (event.key === Qt.Key_Left) {
      selectIndex(wallpaperGrid.currentIndex - 1)
    } else if (event.key === Qt.Key_Down) {
      selectIndex(wallpaperGrid.currentIndex + columns)
    } else if (event.key === Qt.Key_Up) {
      selectIndex(wallpaperGrid.currentIndex - columns)
    } else if (event.key === Qt.Key_Home) {
      selectIndex(0)
    } else if (event.key === Qt.Key_End) {
      selectIndex(wallpaperGrid.count - 1)
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
        || event.key === Qt.Key_Space) {
      if (wallpaperGrid.currentIndex >= 0) {
        WallpaperPickerState.activate(
          WallpaperPickerState.entries[wallpaperGrid.currentIndex])
      }
    } else {
      return
    }
    event.accepted = true
  }

  onOutsideClicked: WallpaperPickerState.close()
  onKeyPressed: (event, editing) => handleKey(event)
  onActiveChanged: if (active) Qt.callLater(resetSelection)

  Text {
    anchors.fill: parent
    anchors.margins: root.theme.menuEntryPadding
    visible: wallpaperGrid.count === 0
    text: WallpaperPickerState.loading
      ? "Loading wallpapers…"
      : WallpaperPickerState.error.length > 0
        ? WallpaperPickerState.error
        : "No wallpapers"
    color: root.theme.menuForeground
    opacity: 0.7
    font.family: root.theme.menuFont
    font.pixelSize: root.theme.menuFontSize
    font.weight: root.theme.menuFontWeight
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  GridView {
    id: wallpaperGrid

    anchors.fill: parent
    anchors.margins: root.cellGap
    visible: count > 0
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    maximumFlickVelocity: 5000
    highlightFollowsCurrentItem: false
    cellWidth: width / root.columns
    cellHeight: root.thumbnailSize
    model: WallpaperPickerState.entries
    currentIndex: -1
    onCountChanged: Qt.callLater(root.resetSelection)

    delegate: Item {
      id: cell

      required property int index
      required property var modelData

      width: wallpaperGrid.cellWidth
      height: wallpaperGrid.cellHeight

      Rectangle {
        anchors.fill: parent
        anchors.margins: root.cellGap / 2
        color: root.theme.menuBorder
        border.color: cell.GridView.isCurrentItem
          ? WallpaperPickerState.action === "remove"
            ? root.theme.urgent
            : root.theme.menuAccent
          : root.theme.menuBorder
        border.width: cell.GridView.isCurrentItem
          ? Math.max(3, root.theme.menuSelectionBorderWidth)
          : root.theme.menuSelectionBorderWidth
        radius: root.theme.menuEntryRadius
        clip: true

        Image {
          anchors.fill: parent
          anchors.margins: parent.border.width
          source: cell.modelData.thumbnail
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: true
        }
      }

      HoverHandler {
        cursorShape: Qt.PointingHandCursor
        onPointChanged: {
          const position = point.scenePosition
          const moved = root.pointerPositionKnown
            && (position.x !== root.pointerPosition.x
              || position.y !== root.pointerPosition.y)
          root.pointerPosition = Qt.point(position.x, position.y)
          root.pointerPositionKnown = true
          if (moved) wallpaperGrid.currentIndex = cell.index
        }
      }
      TapHandler { onTapped: WallpaperPickerState.activate(cell.modelData) }
    }
  }

  MomentumScroll {
    id: momentum
    flickable: wallpaperGrid
  }
}
