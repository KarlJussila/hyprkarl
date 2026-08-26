import QtQuick
import "../../../components"

Item {
  property real progress: -1
  property var theme: null

  AudioIndicator {
    anchors.centerIn: parent
    volume: parent.progress < 0 ? 0.75 : parent.progress / 100
    muted: parent.progress === 0
    indicatorColor: parent.theme.foreground
    inactiveWaveColor: parent.theme.border
    nativeScale: parent.theme.notificationIndicatorScale
  }
}
