pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "../../ui/panels"

Item {
  id: root

  required property var theme
  required property bool active

  readonly property real preferredWidth: theme.panel.width
  property int monthOffset: 0
  readonly property int currentYear: ClockState.date.getFullYear()
  readonly property int currentMonth: ClockState.date.getMonth()
  readonly property date viewedMonth: new Date(currentYear, currentMonth + monthOffset, 1)
  readonly property int viewedYear: viewedMonth.getFullYear()
  readonly property int viewedMonthNumber: viewedMonth.getMonth()

  implicitWidth: parent?.width ?? 0
  implicitHeight: content.implicitHeight

  onActiveChanged: {
    if (!active) return
    monthOffset = 0
  }

  PanelLayout {
    id: content

    width: parent.width
    theme: root.theme
    title: Qt.formatDate(ClockState.date, "dddd, MMMM d")
    subtitle: Qt.formatDateTime(ClockState.date, "yyyy · h:mm:ss AP")

    Row {
      width: parent.width

      CalendarNavButton {
        theme: root.theme
        text: "󰅁"
        navigationSection: "month"
        action: () => root.monthOffset--
      }

      Text {
        width: parent.width - 68
        height: 34
        text: Qt.formatDate(root.viewedMonth, "MMMM yyyy")
        color: root.theme.panel.foreground
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: root.theme.panel.font
        font.pixelSize: root.theme.panel.fontSize + 1
        font.weight: root.theme.panel.fontWeight
        font.styleName: root.theme.typography.style
      }

      CalendarNavButton {
        theme: root.theme
        text: "󰅂"
        navigationSection: "month"
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
        color: root.theme.panel.foreground
        opacity: 0.65
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: root.theme.typography.monoFamily
        font.pixelSize: root.theme.typography.readoutSize
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
        readonly property bool isToday: model.day === ClockState.date.getDate()
          && model.month === ClockState.date.getMonth()
          && model.year === ClockState.date.getFullYear()

        width: calendarGrid.width / 7
        height: calendarGrid.height / 6

        Rectangle {
          anchors.centerIn: parent
          width: Math.min(parent.width, parent.height) - 4
          height: width
          visible: dayCell.isToday
          color: root.theme.panel.background
          border.color: root.theme.panel.accent
          border.width: root.theme.panel.selectionBorderWidth
          radius: root.theme.panel.entryRadius

          Rectangle {
            anchors.fill: parent
            color: root.theme.panel.accent
            opacity: root.theme.panel.selectionAccentOpacity
            radius: parent.radius
          }
        }

        Text {
          anchors.fill: parent
          text: dayCell.model.day
          color: dayCell.isToday ? root.theme.panel.accent : root.theme.panel.foreground
          opacity: dayCell.inViewedMonth ? 1 : 0.35
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          font.family: root.theme.typography.monoFamily
          font.pixelSize: root.theme.typography.readoutSize
          font.weight: dayCell.isToday ? root.theme.panel.fontWeight : Font.Normal
        }
      }
    }

    PanelAction {
      visible: root.monthOffset !== 0
      width: parent.width
      theme: root.theme
      navigationSection: "month-reset"
      icon: "󰃭"
      text: `Return to ${Qt.formatDate(ClockState.date, "MMMM")}`
      action: () => root.monthOffset = 0
    }
  }
}
