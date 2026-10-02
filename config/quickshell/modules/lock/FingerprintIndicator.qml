pragma ComponentBehavior: Bound

import QtQuick

import QtQuick.Shapes
import Quickshell.Io
import "../../ui/animation"

Item {
  id: root
  required property var theme
  required property bool reading
  required property bool failed
  required property bool accepted
  implicitWidth: theme.lock.fingerprintSize
  implicitHeight: implicitWidth
  property real progress: 0
  property real failurePulse: 0
  readonly property color ink: Qt.tint(theme.accent,
    Qt.rgba(theme.urgent.r, theme.urgent.g, theme.urgent.b,
      theme.urgent.a * failurePulse))
  transform: Translate { id: shakeTransform }
  // Material Design Icons fingerprint, matching nf-md-fingerprint (F0237).
  // Centerlines derived from SVG revision f08b713c8eef826e6bfe826c65240326546648ea.
  // https://pictogrammers.com/library/mdi/icon/fingerprint/
  // License: licenses/material-design-icons.txt.
  property FileView source: FileView {
    path: Qt.resolvedUrl("assets/mdi-fingerprint-strokes.svg").toString()
    blockLoading: true
  }
  readonly property string ridges: source.text().match(/\bd="([^"]+)"/)[1]

  Shape {
    anchors.fill: parent
    opacity: failureFeedback.running ? 0.9
      : root.accepted && root.progress === 1 ? 1
      : root.reading || root.accepted ? 0.25 : 0.7
    Behavior on opacity {
      NumberAnimation { duration: root.theme.lock.transitionDuration }
    }
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      fillColor: "transparent"
      strokeColor: root.ink
      strokeWidth: root.width / 24
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      scale: Qt.size(root.width / 24, root.height / 24)
      PathSvg { path: root.ridges }
    }
  }

  Shape {
    anchors.fill: parent
    visible: root.accepted || (root.reading && !root.failed && !failureFeedback.running)
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      fillColor: "transparent"
      strokeColor: root.ink
      strokeWidth: root.width / 24
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      scale: Qt.size(root.width / 24, root.height / 24)
      trim.end: root.progress
      PathSvg { path: root.ridges }
    }
  }

  onFailedChanged: if (failed) failureFeedback.restart()
  ParallelAnimation {
    id: failureFeedback
    onStopped: shakeTransform.x = 0
    SequentialAnimation {
      NumberAnimation {
        target: root; property: "failurePulse"; from: 0; to: 1
        duration: root.theme.lock.transitionDuration
        easing.type: Easing.InOutQuad
      }
      PauseAnimation { duration: root.theme.lock.transitionDuration / 2 }
      NumberAnimation {
        target: root; property: "failurePulse"; to: 0
        duration: root.theme.lock.transitionDuration * 2
        easing.type: Easing.InOutQuad
      }
    }
    ShakeAnimation {
      translation: shakeTransform
      distance: root.width * 0.075
      stepDuration: root.theme.lock.transitionDuration / 2
    }
  }

  NumberAnimation on progress {
    from: 0
    to: 1
    duration: 1200
    loops: Animation.Infinite
    running: root.reading && !root.failed && !root.accepted && !failureFeedback.running
  }

  onAcceptedChanged: if (accepted) {
    failureFeedback.stop()
    failurePulse = 0
    complete.start()
  }
  NumberAnimation {
    id: complete
    target: root
    property: "progress"
    to: 1
    duration: root.theme.lock.fingerprintCompleteDuration
    easing.type: Easing.OutCubic
  }
}
