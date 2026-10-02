pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../ui/panels"

PanelWindow {
  id: root

  required property var output
  required property var theme

  readonly property var flow: PolkitState.flow
  readonly property bool active: PolkitState.requested
    && output.name === PolkitState.resolvedScreenName()
  readonly property string resolvedIcon: flow?.iconName
    ? Quickshell.iconPath(flow.iconName, true)
    : ""
  property real reveal: active ? 1 : 0

  function focusPrompt(): void {
    if (!active) return
    if (flow?.isResponseRequired) responseInput.forceActiveFocus()
    else contentItem.forceActiveFocus()
  }

  function cancel(): void {
    if (flow) flow.cancelAuthenticationRequest()
  }

  function submit(): void {
    if (!flow?.isResponseRequired) return
    flow.submit(responseInput.text)
    responseInput.clear()
  }

  visible: active || reveal > 0
  screen: output
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0

  anchors.top: true
  anchors.bottom: true
  anchors.left: true
  anchors.right: true

  WlrLayershell.namespace: "hyprkarl-quickshell-polkit"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: active
    ? WlrKeyboardFocus.Exclusive
    : WlrKeyboardFocus.None

  Behavior on reveal {
    NumberAnimation {
      duration: root.theme.polkitTransitionDuration
      easing.type: root.active ? Easing.OutCubic : Easing.InCubic
    }
  }

  contentItem {
    focus: root.active

    Keys.onEscapePressed: event => {
      root.cancel()
      event.accepted = true
    }
  }

  onActiveChanged: {
    if (active) {
      responseInput.clear()
      Qt.callLater(focusPrompt)
    }
  }

  onFlowChanged: {
    responseInput.clear()
    Qt.callLater(focusPrompt)
  }

  Connections {
    target: root.flow

    function onIsResponseRequiredChanged(): void {
      responseInput.clear()
      Qt.callLater(root.focusPrompt)
    }

    function onAuthenticationFailed(): void {
      responseInput.clear()
      Qt.callLater(root.focusPrompt)
    }
  }

  MouseArea {
    anchors.fill: parent
  }

  Rectangle {
    id: frame

    anchors.centerIn: parent
    width: Math.min(root.theme.polkitWidth,
      root.width - root.theme.polkitPadding * 2)
    implicitHeight: header.height + divider.height
      + body.implicitHeight + root.theme.polkitPadding * 2
    height: Math.min(implicitHeight,
      root.height - root.theme.polkitPadding * 2)
    color: root.theme.popupSurface
    border.color: root.theme.border
    border.width: root.theme.borderWidth
    radius: root.theme.polkitRadius
    opacity: root.reveal
    scale: 0.96 + root.reveal * 0.04

    MouseArea {
      anchors.fill: parent
    }

    Rectangle {
      id: header

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.leftMargin: root.theme.borderWidth
      anchors.rightMargin: root.theme.borderWidth
      anchors.topMargin: root.theme.borderWidth
      height: headerLabel.implicitHeight + root.theme.polkitPadding * 2
      color: root.theme.popupSurface
      topLeftRadius: Math.max(0,
        root.theme.polkitRadius - root.theme.borderWidth)
      topRightRadius: topLeftRadius
      bottomLeftRadius: 0
      bottomRightRadius: 0

      Rectangle {
        anchors.fill: parent
        color: root.theme.accent
        opacity: root.theme.polkitHeaderAccentOpacity
        topLeftRadius: parent.topLeftRadius
        topRightRadius: parent.topRightRadius
        bottomLeftRadius: 0
        bottomRightRadius: 0
      }

      Text {
        id: headerLabel

        anchors.fill: parent
        anchors.margins: root.theme.polkitPadding
        text: "Authentication Required"
        color: root.theme.foreground
        font.family: root.theme.uiFontFamily
        font.pixelSize: root.theme.bodyFontSize + 1
        font.weight: root.theme.fontWeight
        font.styleName: root.theme.fontStyle
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }

    Rectangle {
      id: divider

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: header.bottom
      height: root.theme.borderWidth
      color: root.theme.border
    }

    ColumnLayout {
      id: body

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: divider.bottom
      anchors.leftMargin: root.theme.polkitPadding
        + root.theme.borderWidth
      anchors.rightMargin: root.theme.polkitPadding
        + root.theme.borderWidth
      anchors.topMargin: root.theme.polkitPadding
      spacing: root.theme.polkitSpacing

      RowLayout {
        Layout.fillWidth: true
        spacing: root.theme.polkitSpacing

        Item {
          implicitWidth: root.theme.polkitIconSize
          implicitHeight: root.theme.polkitIconSize

          IconImage {
            anchors.fill: parent
            visible: root.resolvedIcon.length > 0
            source: root.resolvedIcon
          }

          Text {
            anchors.centerIn: parent
            visible: root.resolvedIcon.length === 0
            text: "󰌾"
            color: root.theme.accent
            font.family: root.theme.uiFontFamily
            font.pixelSize: root.theme.polkitIconSize
            font.weight: root.theme.fontWeight
          }
        }

        Text {
          Layout.fillWidth: true
          text: root.flow?.message ?? ""
          color: root.theme.foreground
          font.family: root.theme.uiFontFamily
          font.pixelSize: root.theme.bodyFontSize
          font.weight: root.theme.fontWeight
          font.styleName: root.theme.fontStyle
          wrapMode: Text.Wrap
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        visible: (root.flow?.identities?.length ?? 0) > 1
        spacing: 2

        Text {
          Layout.fillWidth: true
          text: "Authenticate as"
          color: root.theme.muted
          font.family: root.theme.uiFontFamily
          font.pixelSize: root.theme.readoutFontSize
          font.weight: root.theme.fontWeight
        }

        Repeater {
          model: root.flow?.identities ?? []

          PanelRow {
            required property var modelData

            Layout.fillWidth: true
            theme: root.theme
            icon: modelData.isGroup ? "󰡉" : "󰀄"
            title: modelData.displayName
            detail: modelData.string
            selected: root.flow?.selectedIdentity === modelData
            action: () => root.flow.selectedIdentity = modelData
          }
        }
      }

      Text {
        Layout.fillWidth: true
        visible: text.length > 0
        text: root.flow?.supplementaryMessage
          || (root.flow?.failed ? "Authentication failed. Try again." : "")
        color: root.flow?.supplementaryIsError || root.flow?.failed
          ? root.theme.urgent
          : root.theme.muted
        font.family: root.theme.uiFontFamily
        font.pixelSize: root.theme.readoutFontSize
        font.weight: root.theme.fontWeight
        wrapMode: Text.Wrap
      }

      ColumnLayout {
        Layout.fillWidth: true
        visible: root.flow?.isResponseRequired ?? false
        spacing: 4

        Text {
          Layout.fillWidth: true
          text: root.flow?.inputPrompt ?? "Response"
          color: root.theme.muted
          font.family: root.theme.uiFontFamily
          font.pixelSize: root.theme.readoutFontSize
          font.weight: root.theme.fontWeight
          elide: Text.ElideRight
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 38
          color: root.theme.controlSurface
          border.color: responseInput.activeFocus
            ? root.theme.accent
            : root.theme.border
          border.width: root.theme.borderWidth
          radius: root.theme.controlRadius

          TextInput {
            id: responseInput

            anchors.fill: parent
            anchors.margins: root.theme.controlPadding
            color: root.theme.foreground
            selectionColor: root.theme.accent
            selectedTextColor: root.theme.popupSurface
            font.family: root.theme.monoFontFamily
            font.pixelSize: root.theme.bodyFontSize
            verticalAlignment: TextInput.AlignVCenter
            echoMode: root.flow?.responseVisible
              ? TextInput.Normal
              : TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData
            selectByMouse: true
            activeFocusOnTab: true
            clip: true
            onAccepted: root.submit()
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: root.theme.polkitSpacing

        PanelAction {
          Layout.fillWidth: true
          theme: root.theme
          text: "Cancel"
          action: root.cancel
        }

        PanelAction {
          Layout.fillWidth: true
          visible: root.flow?.isResponseRequired ?? false
          theme: root.theme
          text: "Authenticate"
          action: root.submit
        }
      }
    }
  }
}
