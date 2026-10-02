pragma ComponentBehavior: Bound

import QtQuick
import "../../ui/modal"

ModalWindow {
  id: root

  readonly property bool active: WallpaperPickerState.active
    && output.name === OverlayState.screenName
  readonly property real carouselWidth: Math.floor(
    width * theme.wallpaperPickerWidthScreenFraction)
  readonly property real previewHeight: Math.floor(Math.min(
    height * theme.wallpaperPreviewHeightScreenFraction,
    (carouselWidth - theme.wallpaperPickerGap * 4)
      / theme.wallpaperPreviewAspectRatio))
  readonly property real previewWidth: Math.floor(
    previewHeight * theme.wallpaperPreviewAspectRatio)
  readonly property real cellGap: theme.wallpaperPickerGap
  readonly property real carouselDepth: cellGap
  readonly property var carouselEntries:
    WallpaperPickerState.entries.length === 2
      ? WallpaperPickerState.entries.concat(WallpaperPickerState.entries)
      : WallpaperPickerState.entries

  shown: active
  framed: false

  function resetSelection(): void {
    let index = carouselEntries.findIndex(entry => entry.current)
    if (index < 0 && wallpaperCarousel.count > 0) index = 0
    wallpaperCarousel.currentIndex = index
  }

  function selectIndex(index): void {
    if (wallpaperCarousel.count === 0) return
    wallpaperCarousel.currentIndex = (index + wallpaperCarousel.count)
      % wallpaperCarousel.count
  }

  function moveSelection(offset): void {
    if (wallpaperCarousel.count === 0) return
    if (wallpaperCarousel.currentIndex < 0) {
      resetSelection()
      return
    }
    if (offset > 0) wallpaperCarousel.incrementCurrentIndex()
    else wallpaperCarousel.decrementCurrentIndex()
  }

  function handleKey(event): void {
    if (event.key === Qt.Key_Escape) {
      WallpaperPickerState.close()
    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down
        || event.key === Qt.Key_L || event.key === Qt.Key_J) {
      moveSelection(1)
    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up
        || event.key === Qt.Key_H || event.key === Qt.Key_K) {
      moveSelection(-1)
    } else if (event.key === Qt.Key_Home) {
      selectIndex(0)
    } else if (event.key === Qt.Key_End) {
      selectIndex(wallpaperCarousel.count - 1)
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
        || event.key === Qt.Key_Space) {
      if (wallpaperCarousel.currentIndex >= 0) {
        WallpaperPickerState.activate(
          carouselEntries[wallpaperCarousel.currentIndex])
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
    visible: wallpaperCarousel.count === 0
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

  PathView {
    id: wallpaperCarousel

    anchors.centerIn: parent
    width: root.carouselWidth
    height: root.previewHeight + root.cellGap * 4
    visible: count > 0
    clip: false
    model: root.carouselEntries
    currentIndex: -1
    pathItemCount: Math.min(3, count)
    cacheItemCount: 2
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange
    snapMode: PathView.SnapOneItem
    maximumFlickVelocity: 5000
    highlightMoveDuration: root.theme.panelTransitionDuration
    onCountChanged: Qt.callLater(root.resetSelection)

    path: Path {
      startX: wallpaperCarousel.width / 2
      startY: wallpaperCarousel.height / 2 - root.carouselDepth

      PathAttribute {
        name: "cardScale"
        value: root.theme.wallpaperPreviewSideScale
      }
      PathAttribute {
        name: "cardOpacity"
        value: root.theme.wallpaperPreviewSideOpacity
      }

      PathArc {
        x: wallpaperCarousel.width / 2
        y: wallpaperCarousel.height / 2 + root.carouselDepth
        radiusX: wallpaperCarousel.width
          * root.theme.wallpaperCarouselRadiusWidthFraction
        radiusY: root.carouselDepth
        direction: PathArc.Counterclockwise
      }

      PathAttribute { name: "cardScale"; value: 1 }
      PathAttribute { name: "cardOpacity"; value: 1 }

      PathArc {
        x: wallpaperCarousel.width / 2
        y: wallpaperCarousel.height / 2 - root.carouselDepth
        radiusX: wallpaperCarousel.width
          * root.theme.wallpaperCarouselRadiusWidthFraction
        radiusY: root.carouselDepth
        direction: PathArc.Counterclockwise
      }

      PathAttribute {
        name: "cardScale"
        value: root.theme.wallpaperPreviewSideScale
      }
      PathAttribute {
        name: "cardOpacity"
        value: root.theme.wallpaperPreviewSideOpacity
      }
    }

    delegate: Item {
      id: cell

      required property int index
      required property var modelData

      width: root.previewWidth
      height: root.previewHeight
      // qmllint disable missing-property
      readonly property real pathCardOpacity: cell.PathView.cardOpacity
      z: cell.PathView.cardScale
      scale: cell.PathView.cardScale
      // qmllint enable missing-property

      Rectangle {
        anchors.fill: parent
        color: root.theme.menuBackground
        border.color: cell.PathView.isCurrentItem
          ? WallpaperPickerState.action === "remove"
            ? root.theme.urgent
            : root.theme.menuAccent
          : root.theme.menuBorder
        border.width: cell.PathView.isCurrentItem
          ? Math.max(3, root.theme.menuSelectionBorderWidth)
          : Math.max(2, root.theme.menuSelectionBorderWidth)
        radius: root.theme.menuEntryRadius
        clip: true

        Image {
          anchors.fill: parent
          anchors.margins: parent.border.width
          source: cell.modelData.thumbnail
          sourceSize.width: root.previewWidth
          sourceSize.height: root.previewHeight
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: true
          opacity: cell.pathCardOpacity
        }

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.margins: parent.border.width
          height: wallpaperName.implicitHeight
            + root.theme.menuEntryPadding * 2
          color: root.theme.menuBackground
          opacity: 0.82 * cell.pathCardOpacity

          Text {
            id: wallpaperName

            anchors.fill: parent
            anchors.margins: root.theme.menuEntryPadding
            text: cell.modelData.current
              ? "Current  ·  " + cell.modelData.name
              : cell.modelData.name
            color: root.theme.menuForeground
            font.family: root.theme.menuFont
            font.pixelSize: root.theme.menuFontSize
            font.weight: root.theme.menuFontWeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideMiddle
          }
        }
      }

      HoverHandler { cursorShape: Qt.PointingHandCursor }
      TapHandler {
        onTapped: {
          if (cell.PathView.isCurrentItem) {
            WallpaperPickerState.activate(cell.modelData)
          } else if (cell.x + cell.width / 2 < wallpaperCarousel.width / 2) {
            wallpaperCarousel.decrementCurrentIndex()
          } else {
            wallpaperCarousel.incrementCurrentIndex()
          }
        }
      }
    }
  }
}
