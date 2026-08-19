pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
  id: root

  required property string widgetId
  required property var config
  required property string edge
  required property var barWindow
  required property var theme
  required property var systemState
  required property var panelHost

  readonly property int hostMainPaddingOffset: theme.trayMainPaddingOffset
  readonly property int triggerDividerPadding: Math.max(
    0,
    theme.widgetMainPadding + hostMainPaddingOffset
  )
  readonly property bool towardEnd: config.direction !== "start"
  readonly property real contentX: (width - implicitWidth) / 2
  property bool expanded: false

  implicitWidth: trigger.implicitWidth + trayPanel.width
  implicitHeight: Math.max(trigger.implicitHeight, trayRow.implicitHeight)

  component TrayItem: Item {
    required property var trayItem

    implicitWidth: root.theme.barMinThickness
    implicitHeight: 15
    height: root.height

    IconImage {
      anchors.centerIn: parent
      implicitSize: 15
      source: parent.trayItem.icon
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onClicked: event => {
        if (event.button === Qt.MiddleButton) parent.trayItem.secondaryActivate()
        else if (event.button === Qt.RightButton || parent.trayItem.onlyMenu)
          parent.trayItem.display(root.barWindow, mapToItem(null, 0, height).x, mapToItem(null, 0, height).y)
        else parent.trayItem.activate()
      }
    }
  }

  component TrayTrigger: Item {
    implicitWidth: 8
    implicitHeight: 14
    height: root.height

    Canvas {
      id: chevron
      anchors.centerIn: parent
      anchors.horizontalCenterOffset: -1
      width: 8
      height: 14
      property color indicatorColor: root.theme.foreground
      property bool pointsLeft: root.towardEnd ? root.expanded : !root.expanded

      onIndicatorColorChanged: requestPaint()
      onPointsLeftChanged: requestPaint()

      onPaint: {
        const context = getContext("2d")
        context.clearRect(0, 0, width, height)
        context.strokeStyle = indicatorColor
        context.lineWidth = 1.5
        context.lineCap = "round"
        context.lineJoin = "round"
        context.beginPath()
        if (pointsLeft) {
          context.moveTo(6, 2)
          context.lineTo(2, 7)
          context.lineTo(6, 12)
        } else {
          context.moveTo(2, 2)
          context.lineTo(6, 7)
          context.lineTo(2, 12)
        }
        context.stroke()
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.expanded = !root.expanded
    }
  }

  Item {
    id: trayPanel

    readonly property real innerPadding: trayRow.implicitWidth > 0
      ? root.theme.widgetMainPadding
      : 0

    x: root.contentX + (root.towardEnd ? trigger.width : 0)
    y: 0
    width: root.expanded && trayRow.implicitWidth > 0
      ? trayRow.implicitWidth
        + root.triggerDividerPadding
        + innerPadding
        + root.theme.borderWidth
      : 0
    height: root.height
    clip: true

    Behavior on width {
      NumberAnimation {
        duration: 220
        easing.type: root.expanded ? Easing.OutCubic : Easing.InCubic
      }
    }

    Rectangle {
      x: root.towardEnd
        ? root.triggerDividerPadding
        : trayPanel.width - root.triggerDividerPadding - width
      y: 0
      width: root.theme.borderWidth
      height: parent.height
      color: root.theme.border
    }

    Row {
      id: trayRow

      x: root.towardEnd
        ? root.triggerDividerPadding + root.theme.borderWidth + trayPanel.innerPadding
        : trayPanel.width
          - root.triggerDividerPadding
          - root.theme.borderWidth
          - trayPanel.innerPadding
          - width

      Repeater {
        model: SystemTray.items
        TrayItem {
          required property var modelData
          trayItem: modelData
        }
      }
    }
  }

  TrayTrigger {
    id: trigger

    x: root.contentX + (!root.towardEnd ? trayPanel.width : 0)
    y: 0
  }
}
