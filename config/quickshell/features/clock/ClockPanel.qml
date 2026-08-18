pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "../../components"

Item {
  id: root

  required property var theme
  required property bool active

  property int monthOffset: 0
  readonly property int currentYear: ClockState.now.getFullYear()
  readonly property int currentMonth: ClockState.now.getMonth()
  readonly property date viewedMonth: new Date(currentYear, currentMonth + monthOffset, 1)
  readonly property int viewedYear: viewedMonth.getFullYear()
  readonly property int viewedMonthNumber: viewedMonth.getMonth()

  implicitWidth: parent?.width ?? 0
  implicitHeight: content.implicitHeight

  onActiveChanged: {
    if (!active) return
    ClockState.refresh()
    monthOffset = 0
  }

  Column {
    id: content

    width: parent.width
    spacing: root.theme.panelSpacing

    PanelHeader {
      width: parent.width
      theme: root.theme
      title: Qt.formatDate(ClockState.now, "dddd, MMMM d")
      subtitle: Qt.formatDateTime(ClockState.now, "yyyy · h:mm:ss AP")
    }

    Row {
      width: parent.width

      CalendarNavButton {
        theme: root.theme
        text: "󰅁"
        action: () => root.monthOffset--
      }

      Text {
        width: parent.width - 68
        height: 34
        text: Qt.formatDate(root.viewedMonth, "MMMM yyyy")
        color: root.theme.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: root.theme.fontUi
        font.pixelSize: root.theme.fontSize + 1
        font.weight: root.theme.fontWeight
        font.styleName: root.theme.fontStyle
      }

      CalendarNavButton {
        theme: root.theme
        text: "󰅂"
        action: () => root.monthOffset++
      }
    }

    DayOfWeekRow {
      id: weekdayRow

      width: parent.width
      height: 24
      padding: 0
      spacing: 0
      locale: Qt.locale()
      background: null

      delegate: Text {
        required property var model

        width: weekdayRow.width / 7
        height: weekdayRow.height
        text: model.shortName
        color: root.theme.text
        opacity: 0.65
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: root.theme.fontMono
        font.pixelSize: root.theme.readoutFontSize
        font.capitalization: Font.AllUppercase
      }
    }

    MonthGrid {
      id: calendarGrid

      width: parent.width
      height: 204
      padding: 0
      spacing: 0
      month: root.viewedMonthNumber
      year: root.viewedYear
      locale: Qt.locale()
      background: null

      delegate: Item {
        id: dayCell

        required property var model
        readonly property bool inViewedMonth: model.month === root.viewedMonthNumber
          && model.year === root.viewedYear
        readonly property bool isToday: model.day === ClockState.now.getDate()
          && model.month === ClockState.now.getMonth()
          && model.year === ClockState.now.getFullYear()

        width: calendarGrid.width / 7
        height: calendarGrid.height / 6

        Rectangle {
          anchors.centerIn: parent
          width: Math.min(parent.width, parent.height) - 4
          height: width
          visible: dayCell.isToday
          color: root.theme.accent
          opacity: 0.20
          radius: width / 2
        }

        Text {
          anchors.fill: parent
          text: dayCell.model.day
          color: dayCell.isToday ? root.theme.accent : root.theme.text
          opacity: dayCell.inViewedMonth ? 1 : 0.35
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          font.family: root.theme.fontMono
          font.pixelSize: root.theme.readoutFontSize
          font.weight: dayCell.isToday ? root.theme.fontWeight : Font.Normal
        }
      }
    }

    PanelAction {
      visible: root.monthOffset !== 0
      width: parent.width
      height: visible ? implicitHeight : 0
      theme: root.theme
      icon: "󰃭"
      text: `Return to ${Qt.formatDate(ClockState.now, "MMMM")}`
      action: () => root.monthOffset = 0
    }
  }
}
