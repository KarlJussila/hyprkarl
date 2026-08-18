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

    readonly property Item loadedContent: contentLoader.item as Item
    readonly property real contentHeight: loadedContent?.implicitHeight ?? 0
    readonly property real availableHeight: Math.max(0, root.barWindow.screen.height - root.barWindow.height)

    color: "transparent"
    grabFocus: false
    visible: root.open || root.reveal > 0
    implicitWidth: Math.min(root.theme.panelWidth, root.barWindow.width)
    implicitHeight: Math.min(
      contentHeight + root.theme.panelPadding * 2 + root.theme.borderWidth * 2,
      Math.min(root.theme.panelMaxHeight, availableHeight)
    )
    mask: Region {
      width: root.open ? panel.width : 0
      height: root.open ? panel.height : 0
      topLeftRadius: root.sharpTopLeft ? 0 : root.theme.panelRadius
      topRightRadius: root.sharpTopRight ? 0 : root.theme.panelRadius
      bottomLeftRadius: root.sharpBottomLeft ? 0 : root.theme.panelRadius
      bottomRightRadius: root.sharpBottomRight ? 0 : root.theme.panelRadius
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
          ? root.trigger.height + root.theme.barMarginContent + root.theme.panelGap - root.theme.borderWidth
          : root.theme.borderWidth - root.theme.barMarginContent - root.theme.panelGap
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

    ClippingRectangle {
      id: frame

      anchors.fill: parent
      opacity: root.reveal
      color: root.theme.surface
      border.color: root.theme.border
      border.width: root.theme.borderWidth
      radius: root.theme.panelRadius
      topLeftRadius: root.sharpTopLeft ? 0 : radius
      topRightRadius: root.sharpTopRight ? 0 : radius
      bottomLeftRadius: root.sharpBottomLeft ? 0 : radius
      bottomRightRadius: root.sharpBottomRight ? 0 : radius

      FocusScope {
        id: panelFocus

        anchors.fill: parent
        anchors.margins: root.theme.panelPadding
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
