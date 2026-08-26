pragma ComponentBehavior: Bound

import QtQuick

ModalWindow {
  id: root

  property string title: ""
  property string placeholder: "Search…"
  property bool searchable: true
  property bool showTextCursor: false
  property bool clearQueryOnShow: true
  property real requestedBodyHeight: 0
  property alias query: searchInput.text
  property alias body: pickerBody
  default property alias bodyData: pickerBody.data

  requestedWidth: theme.menuSearchWidth
  requestedHeight: root.theme.menuOuterBorderWidth * 2
    + root.theme.menuOuterPadding * 2
    + root.theme.menuInnerBorderWidth * 2
    + header.height
    + headerDivider.height
    + searchArea.height
    + searchDivider.height
    + root.requestedBodyHeight

  function resetInput(): void {
    if (clearQueryOnShow) searchInput.clear()
    if (searchable) searchInput.forceActiveFocus()
    else contentItem.forceActiveFocus()
  }

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
        text: root.title
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
          text: root.placeholder
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
      visible: root.searchable
      height: visible ? root.theme.menuInnerBorderWidth : 0
      color: root.theme.menuBorder
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
