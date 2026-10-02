pragma ComponentBehavior: Bound

import QtQuick

ModalWindow {
  id: root

  property string title: ""
  property string placeholder: "Search…"
  property bool searchable: true
  property bool searchPinned: true
  property bool showTextCursor: false
  property bool clearQueryOnShow: true
  property real requestedBodyHeight: 0
  property alias query: searchInput.text
  property alias body: pickerBody
  default property alias bodyData: pickerBody.data
  readonly property bool searchShown: searchable
    && (searchPinned || searchInput.text.length > 0)

  requestedWidth: theme.menu.searchWidth
  requestedHeight: root.theme.menu.outerBorderWidth * 2
    + root.theme.menu.outerPadding * 2
    + root.theme.menu.innerBorderWidth * 2
    + header.height
    + headerDivider.height
    + searchArea.height
    + searchDivider.height
    + root.requestedBodyHeight

  function resetInput(): void {
    if (clearQueryOnShow) searchInput.clear()
    if (searchable && searchShown) searchInput.forceActiveFocus()
    else contentItem.forceActiveFocus()
  }

  function focusSearch(): void {
    if (!searchShown) return
    searchInput.forceActiveFocus()
    searchInput.cursorPosition = searchInput.text.length
  }

  onSearchShownChanged: if (shown && !searchShown) Qt.callLater(
    () => contentItem.forceActiveFocus())

  onShownChanged: if (shown) Qt.callLater(root.resetInput)

  Component {
    id: hiddenTextCursor

    Item {}
  }

  Item {
    parent: root.modalBody
    anchors.fill: parent

    Rectangle {
      id: header

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: headerLabel.implicitHeight + root.theme.menu.headerPadding * 2
      color: root.theme.menu.background
      topLeftRadius: Math.max(0,
        root.theme.menu.innerRadius - root.theme.menu.innerBorderWidth)
      topRightRadius: topLeftRadius
      bottomLeftRadius: 0
      bottomRightRadius: 0

      Rectangle {
        anchors.fill: parent
        color: root.theme.menu.accent
        opacity: root.theme.menu.headerAccentOpacity
        topLeftRadius: parent.topLeftRadius
        topRightRadius: parent.topRightRadius
        bottomLeftRadius: 0
        bottomRightRadius: 0
      }

      Text {
        id: headerLabel

        anchors.fill: parent
        anchors.margins: root.theme.menu.headerPadding
        text: root.title
        color: root.theme.menu.foreground
        font.family: root.theme.menu.font
        font.pixelSize: root.theme.menu.fontSize
        font.weight: root.theme.menu.fontWeight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }

    Rectangle {
      id: headerDivider

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: header.bottom
      height: root.theme.menu.innerBorderWidth
      color: root.theme.menu.border
    }

    Rectangle {
      id: searchArea

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: headerDivider.bottom
      visible: root.searchShown
      height: visible
        ? searchInput.implicitHeight
          + root.theme.menu.entryPadding * 2
          + root.theme.menu.entryMargin * 2
        : 0
      color: root.theme.menu.background

      Rectangle {
        anchors.fill: parent
        anchors.margins: root.theme.menu.entryMargin
        color: root.theme.menu.background
        border.color: searchInput.activeFocus && root.showTextCursor
          ? root.theme.menu.accent
          : root.theme.menu.border
        border.width: root.theme.menu.selectionBorderWidth
        radius: root.theme.menu.entryRadius

        Text {
          anchors.fill: parent
          anchors.margins: root.theme.menu.entryPadding
          visible: searchInput.text.length === 0
          text: root.placeholder
          color: root.theme.menu.foreground
          opacity: 0.55
          font.family: root.theme.menu.font
          font.pixelSize: root.theme.menu.fontSize
          font.weight: root.theme.menu.fontWeight
          verticalAlignment: Text.AlignVCenter
        }

        TextInput {
          id: searchInput

          anchors.fill: parent
          anchors.margins: root.theme.menu.entryPadding
          color: root.theme.menu.foreground
          selectionColor: root.theme.menu.accent
          selectedTextColor: root.theme.menu.background
          font.family: root.theme.menu.font
          font.pixelSize: root.theme.menu.fontSize
          font.weight: root.theme.menu.fontWeight
          verticalAlignment: TextInput.AlignVCenter
          cursorDelegate: root.showTextCursor ? null : hiddenTextCursor
          selectByMouse: true
          clip: true
          Keys.onPressed: event => root.keyPressed(event, true)
        }
      }
    }

    Rectangle {
      id: searchDivider

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: searchArea.bottom
      visible: root.searchShown
      height: visible ? root.theme.menu.innerBorderWidth : 0
      color: root.theme.menu.border
    }

    Item {
      id: pickerBody

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: searchDivider.bottom
      anchors.bottom: parent.bottom
      clip: true
    }
  }
}
