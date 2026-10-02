pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "config"
import "modules/lock"

ShellRoot {
  id: root
  property real presentationOpacity: 1
  property bool suspendRequested: false

  function suspendWhenSecure(): void {
    if (suspendRequested && session.secure) {
      suspendProcess.running = true
    }
  }

  Theme { id: lockTheme }
  ShellConfig { id: lockConfig }
  SleepState {
    id: sleepState
    onResumed: root.suspendRequested = false
  }
  LockState {
    id: authentication
    settings: lockConfig.lock
    fingerprintAllowed: session.secure && sleepState.ready && !sleepState.preparing
      && !root.suspendRequested
    onUnlocked: fadeOut.start()
  }

  WlSessionLock {
    id: session
    locked: lockTheme.ready && lockConfig.ready
    onSecureChanged: if (secure) {
      console.info("Hyprkarl lock is secure")
      keyboardLayout.running = true
      root.suspendWhenSecure()
    }

    WlSessionLockSurface {
      color: lockTheme.popupSurface
      LockScreen {
        anchors.fill: parent
        lockState: authentication
        theme: lockTheme
        opacity: root.presentationOpacity
      }
    }
  }

  Process {
    id: keyboardLayout
    command: ["hyprctl", "switchxkblayout", "all", "0"]
  }

  Process {
    id: suspendProcess
    command: ["systemctl", "suspend"]
    // Qt's QProcess::ExitStatus is missing from the installed QML type metadata.
    // qmllint disable signal-handler-parameters
    onExited: exitCode => {
      if (exitCode !== 0) root.suspendRequested = false
    }
    // qmllint enable signal-handler-parameters
  }

  IpcHandler {
    target: "lock"
    function suspend(): void {
      root.suspendRequested = true
      root.suspendWhenSecure()
    }
  }

  Timer {
    interval: 6000
    running: !session.secure
    onTriggered: {
      console.error("Hyprkarl lock did not reach the compositor's secure state")
      session.locked = false
      Qt.exit(1)
    }
  }

  SequentialAnimation {
    id: fadeOut
    PauseAnimation {
      duration: authentication.fingerprintAccepted
        ? lockTheme.lock.fingerprintCompleteDuration : 0
    }
    NumberAnimation {
      target: root
      property: "presentationOpacity"
      from: 1
      to: 0
      duration: lockTheme.lock.fadeDuration
      easing.type: Easing.InOutQuad
    }
    onFinished: {
      session.locked = false
      Qt.quit()
    }
  }
}
