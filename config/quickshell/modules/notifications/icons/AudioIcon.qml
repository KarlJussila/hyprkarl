import QtQuick
import "../../../ui/indicators"

Item {
  property real progress: -1
  property var theme: null

  AudioIndicator {
    anchors.centerIn: parent
    volume: parent.progress < 0 ? 0.75 : parent.progress / 100
    muted: parent.progress === 0
    indicatorColor: parent.theme.palette.foreground
    inactiveWaveColor: parent.theme.palette.border
    nativeScale: parent.theme.notification.indicatorScale
  }
}
