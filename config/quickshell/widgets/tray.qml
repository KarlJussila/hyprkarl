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

  readonly property bool towardEnd: config.direction !== "start"
  property bool expanded: false

  implicitWidth: trigger.implicitWidth + trayPanel.width
  implicitHeight: theme.barThickness

  component TrayItem: Item {
    required property var trayItem

    implicitWidth: root.theme.barThickness
    implicitHeight: root.theme.barThickness

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
    implicitWidth: 18
    implicitHeight: root.theme.barThickness

    Canvas {
      id: chevron
      anchors.centerIn: parent
      anchors.horizontalCenterOffset: -1
      width: 8
      height: 14
      property color indicatorColor: root.theme.text
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

    x: root.towardEnd ? trigger.width : 0
    y: 0
    width: root.expanded ? trayRow.implicitWidth + root.theme.borderWidth : 0
    height: root.theme.barThickness
    clip: true

    Behavior on width {
      NumberAnimation {
        duration: 220
        easing.type: root.expanded ? Easing.OutCubic : Easing.InCubic
      }
    }

    Rectangle {
      x: !root.towardEnd ? trayPanel.width - width : 0
      y: 0
      width: root.theme.borderWidth
      height: root.theme.barThickness
      color: root.theme.border
    }

    Row {
      id: trayRow

      x: root.towardEnd ? root.theme.borderWidth : trayPanel.width - root.theme.borderWidth - width

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

    x: !root.towardEnd ? trayPanel.width : 0
    y: 0
  }
}
