pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../components"
import "../overlay"

OverlayWindow {
  id: root

  readonly property bool active: ApplicationPickerState.active
    && output.name === OverlayState.screenName
  readonly property var entries: ApplicationPickerState.entriesFor(query)
  readonly property real rowHeight: theme.applicationPickerIconSize
    + theme.menuEntryMargin * 2
    + theme.menuSelectionBorderWidth * 2
  property bool pointerPositionKnown: false
  property point pointerPosition: Qt.point(0, 0)

  shown: active
  title: ApplicationPickerState.openWithActive ? "Open With" : "Applications"
  placeholder: "Search applications…"
  requestedWidth: theme.applicationPickerWidth
  requestedBodyHeight: rowHeight * Math.max(1,
    Math.min(theme.applicationPickerRows, entries.length))
    + (ApplicationPickerState.openWithActive ? defaultRow.height : 0)

  function resetSelection(): void {
    momentum.reset()
    applicationList.currentIndex = applicationList.count > 0 ? 0 : -1
    if (applicationList.count > 0) applicationList.positionViewAtBeginning()
  }

  function selectIndex(index): void {
    if (applicationList.count === 0) return
    const next = (index + applicationList.count) % applicationList.count
    applicationList.currentIndex = next
    applicationList.positionViewAtIndex(next, ListView.Contain)
  }

  function moveSelection(offset): void {
    selectIndex(applicationList.currentIndex < 0
      ? (offset > 0 ? 0 : applicationList.count - 1)
      : applicationList.currentIndex + offset)
  }

  function handleKey(event, editing): void {
    if (event.key === Qt.Key_Escape) {
      if (editing && query.length > 0) query = ""
      else ApplicationPickerState.close()
    } else if (event.key === Qt.Key_Down
        || (!editing && event.key === Qt.Key_J)) {
      moveSelection(1)
    } else if (event.key === Qt.Key_Up
        || (!editing && event.key === Qt.Key_K)) {
      moveSelection(-1)
    } else if (event.key === Qt.Key_Home) {
      selectIndex(0)
    } else if (event.key === Qt.Key_End) {
      selectIndex(applicationList.count - 1)
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
        || (!editing && event.key === Qt.Key_Space)) {
      if (applicationList.currentIndex >= 0) {
        ApplicationPickerState.activate(entries[applicationList.currentIndex])
      }
    } else {
      return
    }
    event.accepted = true
  }

  onOutsideClicked: ApplicationPickerState.close()
  onKeyPressed: (event, editing) => handleKey(event, editing)
  onQueryChanged: Qt.callLater(resetSelection)
  onActiveChanged: if (active) Qt.callLater(resetSelection)

  Connections {
    target: ApplicationPickerState
    function onRequested(): void {
      root.query = ""
      Qt.callLater(root.resetSelection)
    }
  }

  Text {
    anchors.fill: parent
    anchors.margins: root.theme.menuEntryPadding
    visible: applicationList.count === 0
    text: ApplicationPickerState.openWithLoading
      ? "Loading applications…"
      : ApplicationPickerState.openWithError.length > 0
        ? ApplicationPickerState.openWithError
        : "No matches"
    color: root.theme.menuForeground
    opacity: 0.7
    font.family: root.theme.menuFont
    font.pixelSize: root.theme.menuFontSize
    font.weight: root.theme.menuFontWeight
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  ListView {
    id: applicationList

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: defaultRow.top
    visible: count > 0
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    maximumFlickVelocity: 5000
    highlightFollowsCurrentItem: false
    model: root.entries
    currentIndex: -1
    onCountChanged: Qt.callLater(root.resetSelection)

    delegate: Item {
      id: row

      required property int index
      required property var modelData

      width: applicationList.width
      height: root.rowHeight

      Rectangle {
        anchors.fill: parent
        anchors.margins: root.theme.menuEntryMargin
        color: root.theme.menuBackground
        border.color: row.ListView.isCurrentItem
          ? root.theme.menuAccent
          : "transparent"
        border.width: row.ListView.isCurrentItem
          ? root.theme.menuSelectionBorderWidth
          : 0
        radius: root.theme.menuEntryRadius

        Rectangle {
          anchors.fill: parent
          color: root.theme.menuAccent
          opacity: row.ListView.isCurrentItem
            ? root.theme.menuSelectionAccentOpacity
            : 0
          radius: parent.radius
        }

        Image {
          id: icon

          anchors.left: parent.left
          anchors.leftMargin: root.theme.menuEntryPadding
          anchors.verticalCenter: parent.verticalCenter
          width: root.theme.applicationPickerIconSize
          height: root.theme.applicationPickerIconSize
          sourceSize.width: width
          sourceSize.height: height
          fillMode: Image.PreserveAspectFit
          source: Quickshell.iconPath(row.modelData.icon,
            "application-x-executable")
        }

        Column {
          anchors.left: icon.right
          anchors.right: defaultMarker.left
          anchors.leftMargin: root.theme.menuEntryPadding
          anchors.rightMargin: root.theme.menuEntryPadding
          anchors.verticalCenter: parent.verticalCenter
          spacing: 1

          Text {
            width: parent.width
            text: row.modelData.name
            color: root.theme.menuForeground
            font.family: root.theme.menuFont
            font.pixelSize: root.theme.menuFontSize
            font.weight: root.theme.menuFontWeight
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            visible: text.length > 0
            text: row.modelData.genericName ?? ""
            color: root.theme.menuForeground
            opacity: 0.6
            font.family: root.theme.menuFont
            font.pixelSize: Math.max(10, root.theme.menuFontSize - 2)
            font.weight: root.theme.menuFontWeight
            elide: Text.ElideRight
          }
        }

        Text {
          id: defaultMarker

          anchors.right: parent.right
          anchors.rightMargin: root.theme.menuEntryPadding
          anchors.verticalCenter: parent.verticalCenter
          visible: row.modelData.isDefault === true
          text: "Default"
          color: root.theme.menuForeground
          opacity: 0.6
          font.family: root.theme.menuFont
          font.pixelSize: Math.max(10, root.theme.menuFontSize - 2)
          font.weight: root.theme.menuFontWeight
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
          if (moved) applicationList.currentIndex = row.index
        }
      }

      TapHandler {
        onTapped: ApplicationPickerState.activate(row.modelData)
      }
    }
  }

  MomentumScroll {
    id: momentum
    flickable: applicationList
  }

  Item {
    id: defaultRow

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    visible: ApplicationPickerState.openWithActive
    height: visible ? 40 : 0

    Rectangle {
      anchors.fill: parent
      color: root.theme.menuBackground

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.theme.menuInnerBorderWidth
        color: root.theme.menuBorder
      }

      Text {
        anchors.left: parent.left
        anchors.leftMargin: root.theme.menuEntryPadding
        anchors.verticalCenter: parent.verticalCenter
        text: ApplicationPickerState.mimeType.length > 0
          ? "Set as default for " + ApplicationPickerState.mimeType
          : "Set as default"
        color: root.theme.menuForeground
        font.family: root.theme.menuFont
        font.pixelSize: root.theme.menuFontSize
        font.weight: root.theme.menuFontWeight
      }

      ToggleIndicator {
        anchors.right: parent.right
        anchors.rightMargin: root.theme.menuEntryPadding
        anchors.verticalCenter: parent.verticalCenter
        active: ApplicationPickerState.setDefault
        theme: root.theme
      }

      HoverHandler { cursorShape: Qt.PointingHandCursor }
      TapHandler {
        onTapped: ApplicationPickerState.setDefault = !ApplicationPickerState.setDefault
      }
    }
  }
}
