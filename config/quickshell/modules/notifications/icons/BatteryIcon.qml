import QtQuick
import "../../../ui/indicators"

Item {
  property real progress: -1
  property var theme: null

  BatteryIndicator {
    anchors.centerIn: parent
    level: parent.progress < 0 ? 1 : parent.progress / 100
    surfaceColor: parent.theme.surfaces.notification
    indicatorColor: parent.theme.palette.foreground
    lowColor: parent.theme.palette.urgent
    accentColor: parent.theme.palette.accent
    nativeScale: parent.theme.notification.indicatorScale
  }
}
