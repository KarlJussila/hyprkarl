pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  required property var output
  required property var theme
  property bool shown: false
  property string title: ""
  property string placeholder: "Search…"
  property bool searchable: true
  property real requestedWidth: theme.menuSearchWidth
  property real requestedBodyHeight: 0
  property real reveal: shown ? 1 : 0
  property alias query: searchInput.text
  property alias body: body
  property alias frame: frame
  default property alias bodyData: body.data

  signal outsideClicked()
  signal keyPressed(var event, bool editing)

  function resetInput(): void {
    searchInput.clear()
    if (searchable) searchInput.forceActiveFocus()
    else contentItem.forceActiveFocus()
  }

  visible: shown || reveal > 0
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "hyprkarl-quickshell-overlay"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: shown
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
      easing.type: root.shown ? Easing.OutCubic : Easing.InCubic
    }
  }

  contentItem {
    focus: root.shown
    Keys.onPressed: event => root.keyPressed(event, false)
  }

  onShownChanged: {
    if (shown) Qt.callLater(root.resetInput)
  }

  Rectangle {
    anchors.fill: parent
    color: root.theme.menuScrim
    opacity: root.reveal

    MouseArea {
      anchors.fill: parent
      onClicked: root.outsideClicked()
    }
  }

  Rectangle {
    id: frame

    readonly property real frameInset: root.theme.menuOuterBorderWidth
      + root.theme.menuOuterPadding
    readonly property real desiredHeight: frameInset * 2
      + root.theme.menuInnerBorderWidth * 3
      + header.height
      + searchArea.height
      + searchDivider.height
      + root.requestedBodyHeight

    anchors.centerIn: parent
    width: Math.min(root.requestedWidth, root.width)
    height: Math.min(desiredHeight, root.height)
    opacity: root.reveal
    color: root.theme.menuBackground
    border.color: root.theme.menuBorder
    border.width: root.theme.menuOuterBorderWidth
    radius: root.theme.menuOuterRadius

    MouseArea { anchors.fill: parent }

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
        id: body

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: searchDivider.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.theme.menuInnerBorderWidth
        anchors.rightMargin: root.theme.menuInnerBorderWidth
        anchors.bottomMargin: root.theme.menuInnerBorderWidth
        clip: true
      }
    }
  }
}
