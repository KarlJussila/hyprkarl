pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import "../../ui/animation"

Rectangle {
  id: root

  required property var lockState
  required property var theme
  readonly property string stateHome: (Quickshell.env("XDG_STATE_HOME")
    ?? Quickshell.env("HOME") + "/.local/state") + "/hyprkarl"

  color: theme.popupSurface

  Image {
    anchors.fill: parent
    source: "file://" + root.stateHome + "/current/wallpaper"
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
  }

  Rectangle {
    anchors.fill: parent
    color: root.theme.popupSurface
    opacity: root.theme.lock.dimOpacity
  }

  Text {
    id: clockLabel
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.height * 0.15
    text: Qt.formatTime(clock.date, root.theme.lock.clockFormat)
    color: root.theme.foreground
    font.family: root.theme.uiFontFamily
    font.pixelSize: root.theme.lock.clockFontSize
    font.weight: root.theme.fontWeight
    renderType: Text.NativeRendering
  }

  Text {
    anchors.horizontalCenter: clockLabel.horizontalCenter
    anchors.top: clockLabel.bottom
    anchors.topMargin: root.theme.lock.spacing / 2
    text: Qt.formatDate(clock.date, root.theme.lock.dateFormat)
    color: root.theme.foreground
    font.family: root.theme.uiFontFamily
    font.pixelSize: root.theme.lock.dateFontSize
    font.weight: root.theme.fontWeight
    renderType: Text.NativeRendering
  }

  Rectangle {
    id: field
    anchors.centerIn: parent
    width: Math.min(root.theme.lock.width,
      root.width - root.theme.lock.padding * 2)
    height: root.theme.lock.inputHeight
    color: root.theme.popupSurface
    border.color: failureHold.running ? root.theme.urgent : root.theme.accent
    border.width: root.theme.borderWidth
    radius: root.theme.lock.radius
    transform: Translate { id: fieldShake }

    Timer {
      id: failureHold
      interval: root.theme.lock.failureDuration
    }

    ShakeAnimation {
      id: passwordShake
      translation: fieldShake
      distance: field.height * 0.075
      stepDuration: root.theme.lock.transitionDuration / 2
    }

    Connections {
      target: root.lockState
      function onPasswordFailedChanged(): void {
        if (root.lockState.passwordFailed) {
          failureHold.restart()
          passwordShake.restart()
        } else {
          failureHold.stop()
          passwordShake.stop()
        }
      }
      function onAuthenticatedChanged(): void {
        if (root.lockState.authenticated) {
          failureHold.stop()
          passwordShake.stop()
        }
      }
    }

    Behavior on border.color {
      ColorAnimation {
        duration: root.theme.lock.transitionDuration
        easing.type: Easing.OutQuint
      }
    }

    ListView {
      id: dots
      anchors.centerIn: parent
      readonly property real dotSize: field.height * 0.25
      width: Math.min(contentWidth, field.width - root.theme.lock.padding * 2)
      height: dotSize
      orientation: ListView.Horizontal
      spacing: dotSize * 0.15
      interactive: false
      clip: true
      visible: !root.lockState.responseVisible
      model: input.text.length || root.lockState.submittedLength
      opacity: root.lockState.passwordBusy ? 0.35 : 1
      Behavior on opacity {
        NumberAnimation { duration: root.theme.lock.transitionDuration }
      }
      delegate: Rectangle {
        required property int index
        width: dots.dotSize
        height: width
        radius: width / 2
        color: root.theme.foreground
      }
      add: Transition {
        NumberAnimation {
          property: "opacity"; from: 0; to: 1
          duration: root.theme.lock.transitionDuration
          easing.type: Easing.OutQuint
        }
      }
      remove: Transition {
        NumberAnimation {
          property: "opacity"; to: 0
          duration: root.theme.lock.transitionDuration
          easing.type: Easing.OutQuint
        }
      }
      Behavior on width {
        NumberAnimation {
          duration: root.theme.lock.transitionDuration
          easing.type: Easing.OutQuint
        }
      }
    }

    TextInput {
      id: input
      anchors.fill: parent
      anchors.margins: root.theme.controlPadding
      focus: true
      enabled: !root.lockState.passwordBusy && !root.lockState.authenticated
      text: root.lockState.currentText
      color: root.theme.foreground
      selectionColor: root.theme.accent
      selectedTextColor: root.theme.popupSurface
      font.family: root.theme.monoFontFamily
      font.pixelSize: root.theme.lock.inputFontSize
      horizontalAlignment: TextInput.AlignHCenter
      verticalAlignment: TextInput.AlignVCenter
      echoMode: root.lockState.responseVisible ? TextInput.Normal : TextInput.NoEcho
      cursorDelegate: Item {}
      inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
      selectByMouse: true
      clip: true
      onTextEdited: root.lockState.currentText = text
      onAccepted: root.lockState.submit()
      Keys.onEscapePressed: root.lockState.clearAttempt()
      onEnabledChanged: if (enabled) forceActiveFocus()
    }
  }

  FingerprintIndicator {
    anchors.horizontalCenter: field.horizontalCenter
    anchors.bottom: field.top
    anchors.bottomMargin: root.theme.lock.spacing
    visible: root.lockState.fingerprintEnabled
    theme: root.theme
    reading: root.lockState.fingerprintReading
    failed: root.lockState.fingerprintFailed
    accepted: root.lockState.fingerprintAccepted
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
