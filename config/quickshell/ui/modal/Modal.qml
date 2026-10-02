pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../navigation"

Scope {
  id: root

  required property var context
  required property string name
  property string title: ""
  property string subtitle: ""
  property real preferredWidth: context.theme.menuSearchWidth
  property real preferredHeight: 480
  property Component body: null
  property Component footer: null
  property var dismissAction: null
  readonly property bool active: context.overlayName === name

  function dismiss(): void {
    if (dismissAction !== null) {
      dismissAction()
    } else {
      close()
    }
  }

  function open(output: string, values: var): bool {
    return context.openOverlay(name, output, values ?? ({}))
  }

  function replace(output: string, values: var): bool {
    return context.replaceOverlay(name, output, values ?? ({}))
  }

  function toggle(output: string, values: var): bool {
    return context.toggleOverlay(name, output, values ?? ({}))
  }

  function close(): void {
    if (active) context.closeOverlay()
  }

  Variants {
    model: root.context.outputs

    ModalWindow {
      id: window

      required property var modelData
      readonly property bool requested: modelData !== null
        && root.active
        && root.context.overlayOutput === modelData.name
      readonly property real contentPadding: root.context.theme.menuEntryPadding * 2

      output: modelData
      theme: root.context.theme
      shown: requested
      requestedWidth: root.preferredWidth
      requestedHeight: root.preferredHeight
      onOutsideClicked: if (requested) root.dismiss()
      onKeyPressed: (event, editing) => {
        if (!requested) return
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
          root.dismiss()
        } else if (!navigator.handleKey(event)) {
          return
        }
        event.accepted = true
      }

      KeyboardNavigator {
        id: navigator
        navigationRoot: window.modalBody
      }

      Shortcut {
        sequence: "Tab"
        context: Qt.WindowShortcut
        enabled: window.shown
        onActivated: navigator.moveSection(1)
      }

      Shortcut {
        sequence: "Shift+Tab"
        context: Qt.WindowShortcut
        enabled: window.shown
        onActivated: navigator.moveSection(-1)
      }

      onShownChanged: NavigationState.clear()

      Item {
        parent: window.modalBody
        anchors.fill: parent

        Rectangle {
          id: header

          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          height: titleLabel.implicitHeight
            + (subtitleLabel.visible ? subtitleLabel.implicitHeight + 2 : 0)
            + window.contentPadding * 2
          color: root.context.theme.menuBackground

          Rectangle {
            anchors.fill: parent
            color: root.context.theme.menuAccent
            opacity: root.context.theme.menuHeaderAccentOpacity
          }

          Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: window.contentPadding
            anchors.rightMargin: window.contentPadding
            spacing: 2

            Text {
              id: titleLabel

              width: parent.width
              text: root.title
              color: root.context.theme.menuForeground
              font.family: root.context.theme.menuFont
              font.pixelSize: root.context.theme.menuFontSize
              font.weight: root.context.theme.menuFontWeight
              elide: Text.ElideRight
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              id: subtitleLabel

              visible: root.subtitle.length > 0
              width: parent.width
              text: root.subtitle
              color: root.context.theme.menuForeground
              opacity: 0.65
              font.family: root.context.theme.menuFont
              font.pixelSize: root.context.theme.readoutFontSize
              elide: Text.ElideRight
              horizontalAlignment: Text.AlignHCenter
            }
          }
        }

        Rectangle {
          id: headerDivider

          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: header.bottom
          height: root.context.theme.menuInnerBorderWidth
          color: root.context.theme.menuBorder
        }

        Item {
          id: bodyArea

          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: headerDivider.bottom
          anchors.bottom: footerDivider.top
          anchors.margins: window.contentPadding

          Loader {
            anchors.fill: parent
            active: window.shown || window.reveal > 0
            sourceComponent: root.body
          }
        }

        Rectangle {
          id: footerDivider

          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: footerArea.top
          visible: root.footer !== null
          height: visible ? root.context.theme.menuInnerBorderWidth : 0
          color: root.context.theme.menuBorder
        }

        Item {
          id: footerArea

          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          visible: root.footer !== null
          height: visible
            ? footerLoader.implicitHeight + window.contentPadding * 2
            : 0

          Loader {
            id: footerLoader

            anchors.fill: parent
            anchors.margins: window.contentPadding
            active: footerArea.visible && (window.shown || window.reveal > 0)
            sourceComponent: root.footer
          }
        }
      }
    }
  }
}
