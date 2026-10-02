import QtQml
import Quickshell
import Quickshell.Io

QtObject {
  id: root
  default property Component surface
  property bool locked: false
  property bool confirmed: false
  readonly property bool secure: locked && confirmed

  property FileView gate: FileView {
    path: Quickshell.env("LOCK_TEST_GATE")
    watchChanges: true
    onFileChanged: reload()
  }

  property Timer confirmation: Timer {
    interval: 20
    repeat: true
    running: root.locked && !root.confirmed
    onTriggered: if (root.gate.text().trim() === "secure") root.confirmed = true
  }
}
