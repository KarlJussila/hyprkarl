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

  Theme { id: lockTheme }
  SleepState { id: sleepState }
  LockState {
    id: authentication
    fingerprintAllowed: session.secure && sleepState.ready && !sleepState.preparing
    onUnlocked: fadeOut.start()
  }

  // Lock first; the theme only decorates. Unlock, or the compositor
  // rejecting the lock, ends the process.
  WlSessionLock {
    id: session
    locked: true
    onLockedChanged: if (!locked) Qt.quit()
    onSecureChanged: if (secure) keyboardLayout.running = true

    WlSessionLockSurface {
      color: "black"
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
    onFinished: session.locked = false
  }
}
