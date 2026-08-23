pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../components"

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
  readonly property Item focusedControl: root.open
    ? NavigationState.currentItem
    : null
  readonly property var keyTargets: !root.open
    ? []
    : focusedControl && focusedControl !== panelFocus
      ? [sectionKeyTarget, focusedControl, panelFocus]
      : [sectionKeyTarget, panelFocus]

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
    NavigationState.clear()
    unloadTimer.restart()
  }

  function focusPanel(): void {
    if (!open) return
    panelFocus.forceActiveFocus()
    panel.anchor.updateAnchor()
    Qt.callLater(() => {
      if (!root.open) return
      navigator.focusInitialItem()
      barWindow.contentItem.forceActiveFocus()
      barWindow.requestActivate()
    })
  }

  KeyboardNavigator {
    id: navigator
    navigationRoot: panel.loadedContent
    viewport: viewport
  }

  Item {
    id: sectionKeyTarget

    Keys.onPressed: event => {
      if (event.key !== Qt.Key_Tab && event.key !== Qt.Key_Backtab) return
      navigator.handleKey(event)
      event.accepted = true
    }
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

    Shortcut {
      sequence: "Tab"
      context: Qt.WindowShortcut
      enabled: root.open
      onActivated: navigator.moveSection(1)
    }

    Shortcut {
      sequence: "Shift+Tab"
      context: Qt.WindowShortcut
      enabled: root.open
      onActivated: navigator.moveSection(-1)
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
            Keys.onPressed: event => {
              if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                root.close()
              } else if (!navigator.handleKey(event)) {
                return
              }
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

              Rectangle {
                readonly property rect sectionRect: navigator.currentSectionRect
                readonly property rect sectionBounds: navigator.currentSectionBounds
                readonly property rect contentBounds: navigator.currentContentBounds
                readonly property real verticalInset: root.theme.panelSpacing / 2
                readonly property bool firstSection: contentBounds.height > 0
                  && Math.abs(sectionRect.y - contentBounds.y) < 0.5
                readonly property bool lastSection: contentBounds.height > 0
                  && Math.abs(
                    sectionRect.y + sectionRect.height
                      - contentBounds.y - contentBounds.height
                  ) < 0.5
                readonly property real topInset: firstSection
                  ? sectionRect.y - sectionBounds.y
                  : verticalInset
                readonly property real bottomInset: lastSection
                  ? sectionBounds.y + sectionBounds.height
                    - sectionRect.y - sectionRect.height
                  : verticalInset

                x: root.theme.panelInnerBorderWidth
                y: Math.max(0, sectionRect.y - topInset)
                width: Math.max(0, viewport.width - x * 2)
                height: sectionRect.height + topInset + bottomInset
                visible: root.open && sectionRect.width > 0 && sectionRect.height > 0
                color: root.theme.panelSectionBackground
              }

              Loader {
                id: contentLoader

                width: viewport.width
                height: panel.loadedContent?.implicitHeight ?? 0
                sourceComponent: root.contentComponent
                onLoaded: if (root.open) Qt.callLater(navigator.focusInitialItem)
              }
            }
          }
        }
      }
    }
  }
}
