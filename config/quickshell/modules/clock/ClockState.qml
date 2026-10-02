pragma Singleton

import QtQuick

QtObject {
  id: root

  property date now: new Date()

  function refresh(): void {
    now = new Date()
  }

  property Timer tick: Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }
}
