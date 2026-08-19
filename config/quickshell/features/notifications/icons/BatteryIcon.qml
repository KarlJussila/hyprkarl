import QtQuick
import "../../../components"

Item {
  property real progress: -1
  property var theme: null

  BatteryIndicator {
    anchors.centerIn: parent
    level: parent.progress < 0 ? 1 : parent.progress / 100
    surfaceColor: parent.theme.notificationSurface
    indicatorColor: parent.theme.foreground
    lowColor: parent.theme.urgent
    accentColor: parent.theme.accent
    nativeScale: parent.theme.notificationIndicatorScale
  }
}
