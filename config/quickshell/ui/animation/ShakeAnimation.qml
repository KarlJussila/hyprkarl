import QtQuick

SequentialAnimation {
  id: root
  required property Translate translation
  required property real distance
  required property int stepDuration

  onStopped: translation.x = 0

  NumberAnimation {
    target: root.translation; property: "x"; from: 0; to: -root.distance
    duration: root.stepDuration
    easing.type: Easing.InOutSine
  }
  NumberAnimation {
    target: root.translation; property: "x"; to: root.distance
    duration: root.stepDuration
    easing.type: Easing.InOutSine
  }
  NumberAnimation {
    target: root.translation; property: "x"; to: -root.distance / 2
    duration: root.stepDuration
    easing.type: Easing.InOutSine
  }
  NumberAnimation {
    target: root.translation; property: "x"; to: root.distance / 4
    duration: root.stepDuration
    easing.type: Easing.InOutSine
  }
  NumberAnimation {
    target: root.translation; property: "x"; to: 0
    duration: root.stepDuration
    easing.type: Easing.InOutSine
  }
}
