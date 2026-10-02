pragma ComponentBehavior: Bound

import QtQuick
import "../../ui/modal"

Modal {
  id: root

  required property var shellContext

  context: shellContext
  name: DisplayConfirmationState.surface
  title: "Keep display changes?"
  subtitle: DisplayConfirmationState.remainingSeconds === 1
    ? "Reverting in 1 second"
    : `Reverting in ${DisplayConfirmationState.remainingSeconds} seconds`
  preferredWidth: shellContext.theme.menuSearchWidth
  preferredHeight: 250
  dismissAction: () => DisplayConfirmationState.revert()

  body: Component {
    Column {
      spacing: root.shellContext.theme.menuEntryPadding * 2

      Text {
        width: parent.width
        text: "Confirm that the new layout is visible and usable. It will be restored automatically if you do nothing."
        color: root.shellContext.theme.menuForeground
        font.family: root.shellContext.theme.menuFont
        font.pixelSize: root.shellContext.theme.menuFontSize
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
      }

      Rectangle {
        width: parent.width
        height: 6
        color: root.shellContext.theme.menuBorder
        radius: height / 2

        Rectangle {
          width: parent.width * DisplayConfirmationState.remainingFraction
          height: parent.height
          color: root.shellContext.theme.menuAccent
          radius: parent.radius
        }
      }
    }
  }

  footer: Component {
    Item {
      implicitHeight: 34

      ModalButton {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        theme: root.shellContext.theme
        text: "Revert now"
        enabled: !DisplayConfirmationState.resolving
        action: () => DisplayConfirmationState.revert()
      }

      ModalButton {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        theme: root.shellContext.theme
        text: DisplayConfirmationState.resolving ? "Saving…" : "Keep changes"
        accent: true
        enabled: !DisplayConfirmationState.resolving
        action: () => DisplayConfirmationState.confirm()
      }
    }
  }
}
