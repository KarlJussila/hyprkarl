pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../ui/controls"
import "../../ui/modal"

PickerWindow {
  id: root

  readonly property bool active: ApplicationPickerState.active
    && output.name === OverlayState.screenName
  required property var hidden
  readonly property var entries: ApplicationPickerState.entriesFor(query, hidden)
  readonly property real rowHeight: theme.applicationPicker.iconSize
    + theme.menu.entryMargin * 2
    + theme.menu.selectionBorderWidth * 2

  shown: active
  title: ApplicationPickerState.openWithActive ? "Open With" : "Applications"
  placeholder: "Search applications…"
  requestedWidth: theme.applicationPicker.width
  requestedBodyHeight: rowHeight * Math.max(1,
    Math.min(theme.applicationPicker.rows, entries.length))
    + (ApplicationPickerState.openWithActive ? defaultRow.height : 0)

  function resetSelection(): void {
    momentum.reset()
    pointerPositionKnown = false
    applicationList.currentIndex = applicationList.count > 0 ? 0 : -1
    selectionVisible = applicationList.currentIndex >= 0
    if (applicationList.count > 0) applicationList.positionViewAtBeginning()
  }

  function selectIndex(index): void {
    if (applicationList.count === 0) return
    const next = (index + applicationList.count) % applicationList.count
    applicationList.currentIndex = next
    applicationList.positionViewAtIndex(next, ListView.Contain)
  }

  function moveSelection(offset): void {
    if (applicationList.count === 0) return
    selectIndex(applicationList.currentIndex < 0
      ? (offset > 0 ? 0 : applicationList.count - 1)
      : applicationList.currentIndex + offset)
    selectionVisible = applicationList.currentIndex >= 0
  }

  function handleKey(event, editing): void {
    if (event.key === Qt.Key_Escape) {
      ApplicationPickerState.close()
    } else if (query.length === 0
        && (event.key === Qt.Key_Left
          || (!editing && event.key === Qt.Key_H))) {
      if (!ApplicationPickerState.back()) ApplicationPickerState.close()
    } else if (event.key === Qt.Key_Down
        || (!editing && event.key === Qt.Key_J)) {
      moveSelection(1)
    } else if (event.key === Qt.Key_Up
        || (!editing && event.key === Qt.Key_K)) {
      moveSelection(-1)
    } else if (event.key === Qt.Key_Home) {
      selectIndex(0)
      selectionVisible = applicationList.currentIndex >= 0
    } else if (event.key === Qt.Key_End) {
      selectIndex(applicationList.count - 1)
      selectionVisible = applicationList.currentIndex >= 0
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
    anchors.margins: root.theme.menu.entryPadding
    visible: applicationList.count === 0
    text: ApplicationPickerState.openWithLoading
      ? "Loading applications…"
      : ApplicationPickerState.openWithError.length > 0
        ? ApplicationPickerState.openWithError
        : "No matches"
    color: root.theme.menu.foreground
    opacity: 0.7
    font.family: root.theme.menu.font
    font.pixelSize: root.theme.menu.fontSize
    font.weight: root.theme.menu.fontWeight
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
      readonly property bool navigationCurrent:
        root.selectionVisible && row.ListView.isCurrentItem

      width: applicationList.width
      height: root.rowHeight

      Rectangle {
        anchors.fill: parent
        anchors.margins: root.theme.menu.entryMargin
        color: root.theme.menu.background
        border.color: row.navigationCurrent
          ? root.theme.menu.accent
          : "transparent"
        border.width: row.navigationCurrent
          ? root.theme.menu.selectionBorderWidth
          : 0
        radius: root.theme.menu.entryRadius

        Rectangle {
          anchors.fill: parent
          color: root.theme.menu.accent
          opacity: row.navigationCurrent
            ? root.theme.menu.selectionAccentOpacity
            : 0
          radius: parent.radius
        }

        Image {
          id: icon

          anchors.left: parent.left
          anchors.leftMargin: root.theme.menu.entryPadding
          anchors.verticalCenter: parent.verticalCenter
          width: root.theme.applicationPicker.iconSize
          height: root.theme.applicationPicker.iconSize
          sourceSize.width: width
          sourceSize.height: height
          fillMode: Image.PreserveAspectFit
          source: Quickshell.iconPath(row.modelData.icon,
            "application-x-executable")
        }

        Column {
          anchors.left: icon.right
          anchors.right: defaultMarker.left
          anchors.leftMargin: root.theme.menu.entryPadding
          anchors.rightMargin: root.theme.menu.entryPadding
          anchors.verticalCenter: parent.verticalCenter
          spacing: 1

          Text {
            width: parent.width
            text: row.modelData.name
            color: root.theme.menu.foreground
            font.family: root.theme.menu.font
            font.pixelSize: root.theme.menu.fontSize
            font.weight: root.theme.menu.fontWeight
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            visible: text.length > 0
            text: row.modelData.genericName ?? ""
            color: root.theme.menu.foreground
            opacity: 0.6
            font.family: root.theme.menu.font
            font.pixelSize: Math.max(10, root.theme.menu.fontSize - 2)
            font.weight: root.theme.menu.fontWeight
            elide: Text.ElideRight
          }
        }

        Text {
          id: defaultMarker

          anchors.right: parent.right
          anchors.rightMargin: root.theme.menu.entryPadding
          anchors.verticalCenter: parent.verticalCenter
          visible: row.modelData.isDefault === true
          text: "Default"
          color: root.theme.menu.foreground
          opacity: 0.6
          font.family: root.theme.menu.font
          font.pixelSize: Math.max(10, root.theme.menu.fontSize - 2)
          font.weight: root.theme.menu.fontWeight
        }
      }

      HoverHandler {
        cursorShape: Qt.PointingHandCursor
        onPointChanged: {
          if (!root.pointerMoved(point.scenePosition)) return
          applicationList.currentIndex = row.index
          root.selectionVisible = true
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
      color: root.theme.menu.background

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.theme.menu.innerBorderWidth
        color: root.theme.menu.border
      }

      Text {
        anchors.left: parent.left
        anchors.leftMargin: root.theme.menu.entryPadding
        anchors.verticalCenter: parent.verticalCenter
        text: ApplicationPickerState.mimeType.length > 0
          ? "Set as default for " + ApplicationPickerState.mimeType
          : "Set as default"
        color: root.theme.menu.foreground
        font.family: root.theme.menu.font
        font.pixelSize: root.theme.menu.fontSize
        font.weight: root.theme.menu.fontWeight
      }

      ToggleIndicator {
        anchors.right: parent.right
        anchors.rightMargin: root.theme.menu.entryPadding
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
