pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

Scope {
  id: root

  required property var barWindow
  required property string edge
  required property var theme

  property string activeId: ""
  property Item trigger: null
  property Component contentComponent: null
  property bool open: false
  property real reveal: open ? 1 : 0
  property real anchorX: 0

  readonly property bool touchesBar: theme.panelGap === 0 && theme.barMarginContent === 0
  readonly property bool touchesLeft: anchorX <= 0.5
  readonly property bool touchesRight: anchorX + panel.width >= barWindow.width - 0.5
  readonly property bool sharpTopLeft: touchesBar && edge === "top" && touchesLeft
  readonly property bool sharpTopRight: touchesBar && edge === "top" && touchesRight
  readonly property bool sharpBottomLeft: touchesBar && edge === "bottom" && touchesLeft
  readonly property bool sharpBottomRight: touchesBar && edge === "bottom" && touchesRight
  readonly property real frameInset: theme.panelOuterPadding
  readonly property real frameOverhead: theme.panelOuterBorderWidth * 2
    + frameInset * 2
    + theme.panelInnerBorderWidth * 2

  function toggle(id: string, item: Item, component: Component): void {
    if (activeId === id) {
      close()
      return
    }

    unloadTimer.stop()
    activeId = id
    trigger = item
    contentComponent = component

    if (!open) {
      Qt.callLater(() => {
        if (root.activeId !== id) return
        root.open = true
        Qt.callLater(root.focusPanel)
      })
    } else {
      Qt.callLater(() => {
        if (root.activeId !== id) return
        panel.anchor.updateAnchor()
        root.focusPanel()
      })
    }
  }

  function close(): void {
    if (!open && activeId.length === 0) return
    activeId = ""
    open = false
    unloadTimer.restart()
  }

  function focusPanel(): void {
    if (!open) return
    panelFocus.forceActiveFocus()
    panel.anchor.updateAnchor()
  }

  Behavior on reveal {
    NumberAnimation {
      duration: root.theme.panelTransitionDuration
      easing.type: root.open ? Easing.OutCubic : Easing.InCubic
    }
  }

  Timer {
    id: unloadTimer
    interval: root.theme.panelTransitionDuration
    onTriggered: {
      if (root.open) return
      root.trigger = null
      root.contentComponent = null
    }
  }

  HyprlandFocusGrab {
    windows: [root.barWindow, panel]
    active: root.open && panel.visible
    onCleared: {
      if (root.open) root.close()
    }
  }

  PopupWindow {
    id: panel

    readonly property var loadedContent: contentLoader.item
    readonly property real contentHeight: loadedContent?.implicitHeight ?? 0
    readonly property real availableHeight: Math.max(0, root.barWindow.screen.height - root.barWindow.height)

    color: "transparent"
    grabFocus: false
    visible: root.open || root.reveal > 0
    implicitWidth: Math.min(loadedContent?.preferredWidth ?? root.theme.panelWidth, root.barWindow.width)
    implicitHeight: Math.min(
      contentHeight + root.frameOverhead,
      availableHeight
    )
    mask: Region {
      width: root.open ? panel.width : 0
      height: root.open ? panel.height : 0
      topLeftRadius: root.sharpTopLeft ? 0 : root.theme.panelOuterRadius
      topRightRadius: root.sharpTopRight ? 0 : root.theme.panelOuterRadius
      bottomLeftRadius: root.sharpBottomLeft ? 0 : root.theme.panelOuterRadius
      bottomRightRadius: root.sharpBottomRight ? 0 : root.theme.panelOuterRadius
    }

    anchor {
      window: root.barWindow
      adjustment: PopupAdjustment.ResizeY
      gravity: root.edge === "top"
        ? Edges.Bottom | Edges.Right
        : Edges.Top | Edges.Right

      onAnchoring: {
        if (!root.trigger) return

        const relativeY = root.edge === "top"
          ? root.trigger.height + root.theme.barMarginContent + root.theme.panelGap - root.theme.panelOuterBorderWidth
          : root.theme.panelOuterBorderWidth - root.theme.barMarginContent - root.theme.panelGap
        const point = root.trigger.QsWindow.contentItem.mapFromItem(
          root.trigger,
          root.trigger.width / 2 - panel.width / 2,
          relativeY
        )

        root.anchorX = Math.max(0, Math.min(root.barWindow.width - panel.width, point.x))
        anchor.rect.x = root.anchorX
        anchor.rect.y = point.y
      }
    }

    Item {
      id: revealClip

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: root.edge === "top" ? parent.top : undefined
      anchors.bottom: root.edge === "bottom" ? parent.bottom : undefined
      height: parent.height * root.reveal
      clip: true
      opacity: root.reveal

      ClippingRectangle {
        id: frame

        width: parent.width
        height: panel.height
        anchors.top: root.edge === "top" ? parent.top : undefined
        anchors.bottom: root.edge === "bottom" ? parent.bottom : undefined
        color: root.theme.panelBackground
        border.color: root.theme.panelBorder
        border.width: root.theme.panelOuterBorderWidth
        radius: root.theme.panelOuterRadius
        topLeftRadius: root.sharpTopLeft ? 0 : radius
        topRightRadius: root.sharpTopRight ? 0 : radius
        bottomLeftRadius: root.sharpBottomLeft ? 0 : radius
        bottomRightRadius: root.sharpBottomRight ? 0 : radius

        ClippingRectangle {
          id: innerFrame

          anchors.fill: parent
          anchors.margins: root.frameInset
          color: root.theme.panelBackground
          border.color: root.theme.panelBorder
          border.width: root.theme.panelInnerBorderWidth
          radius: root.theme.panelInnerRadius
          topLeftRadius: root.sharpTopLeft ? 0 : radius
          topRightRadius: root.sharpTopRight ? 0 : radius
          bottomLeftRadius: root.sharpBottomLeft ? 0 : radius
          bottomRightRadius: root.sharpBottomRight ? 0 : radius

          FocusScope {
            id: panelFocus

            anchors.fill: parent
            focus: panel.visible
            Keys.onEscapePressed: event => {
              root.close()
              event.accepted = true
            }

            Flickable {
              id: viewport

              anchors.fill: parent
              contentWidth: width
              contentHeight: panel.loadedContent?.implicitHeight ?? 0
              clip: true
              interactive: contentHeight > height
              boundsBehavior: Flickable.StopAtBounds

              Loader {
                id: contentLoader

                width: viewport.width
                height: panel.loadedContent?.implicitHeight ?? 0
                sourceComponent: root.contentComponent
              }
            }
          }
        }
      }
    }
  }
}
