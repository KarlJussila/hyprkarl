pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../ui/panels"
import "../../config"

PanelWindow {
  id: root

  required property var output
  required property var theme

  readonly property var flow: PolkitState.flow
  readonly property bool active: PolkitState.requested
    && output.name === Screens.resolve(PolkitState.screenName)
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
      duration: root.theme.polkit.transitionDuration
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
    width: Math.min(root.theme.polkit.width,
      root.width - root.theme.polkit.padding * 2)
    implicitHeight: header.height + divider.height
      + body.implicitHeight + root.theme.polkit.padding * 2
    height: Math.min(implicitHeight,
      root.height - root.theme.polkit.padding * 2)
    color: root.theme.surfaces.popup
    border.color: root.theme.palette.border
    border.width: root.theme.metrics.borderWidth
    radius: root.theme.polkit.radius
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
      anchors.leftMargin: root.theme.metrics.borderWidth
      anchors.rightMargin: root.theme.metrics.borderWidth
      anchors.topMargin: root.theme.metrics.borderWidth
      height: headerLabel.implicitHeight + root.theme.polkit.padding * 2
      color: root.theme.surfaces.popup
      topLeftRadius: Math.max(0,
        root.theme.polkit.radius - root.theme.metrics.borderWidth)
      topRightRadius: topLeftRadius
      bottomLeftRadius: 0
      bottomRightRadius: 0

      Rectangle {
        anchors.fill: parent
        color: root.theme.palette.accent
        opacity: root.theme.polkit.headerAccentOpacity
        topLeftRadius: parent.topLeftRadius
        topRightRadius: parent.topRightRadius
        bottomLeftRadius: 0
        bottomRightRadius: 0
      }

      Text {
        id: headerLabel

        anchors.fill: parent
        anchors.margins: root.theme.polkit.padding
        text: "Authentication Required"
        color: root.theme.palette.foreground
        font.family: root.theme.typography.uiFamily
        font.pixelSize: root.theme.typography.bodySize + 1
        font.weight: root.theme.typography.weight
        font.styleName: root.theme.typography.style
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }

    Rectangle {
      id: divider

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: header.bottom
      height: root.theme.metrics.borderWidth
      color: root.theme.palette.border
    }

    ColumnLayout {
      id: body

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: divider.bottom
      anchors.leftMargin: root.theme.polkit.padding
        + root.theme.metrics.borderWidth
      anchors.rightMargin: root.theme.polkit.padding
        + root.theme.metrics.borderWidth
      anchors.topMargin: root.theme.polkit.padding
      spacing: root.theme.polkit.spacing

      RowLayout {
        Layout.fillWidth: true
        spacing: root.theme.polkit.spacing

        Item {
          implicitWidth: root.theme.polkit.iconSize
          implicitHeight: root.theme.polkit.iconSize

          IconImage {
            anchors.fill: parent
            visible: root.resolvedIcon.length > 0
            source: root.resolvedIcon
          }

          Text {
            anchors.centerIn: parent
            visible: root.resolvedIcon.length === 0
            text: "󰌾"
            color: root.theme.palette.accent
            font.family: root.theme.typography.uiFamily
            font.pixelSize: root.theme.polkit.iconSize
            font.weight: root.theme.typography.weight
          }
        }

        Text {
          Layout.fillWidth: true
          text: root.flow?.message ?? ""
          color: root.theme.palette.foreground
          font.family: root.theme.typography.uiFamily
          font.pixelSize: root.theme.typography.bodySize
          font.weight: root.theme.typography.weight
          font.styleName: root.theme.typography.style
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
          color: root.theme.palette.muted
          font.family: root.theme.typography.uiFamily
          font.pixelSize: root.theme.typography.readoutSize
          font.weight: root.theme.typography.weight
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
          ? root.theme.palette.urgent
          : root.theme.palette.muted
        font.family: root.theme.typography.uiFamily
        font.pixelSize: root.theme.typography.readoutSize
        font.weight: root.theme.typography.weight
        wrapMode: Text.Wrap
      }

      ColumnLayout {
        Layout.fillWidth: true
        visible: root.flow?.isResponseRequired ?? false
        spacing: 4

        Text {
          Layout.fillWidth: true
          text: root.flow?.inputPrompt ?? "Response"
          color: root.theme.palette.muted
          font.family: root.theme.typography.uiFamily
          font.pixelSize: root.theme.typography.readoutSize
          font.weight: root.theme.typography.weight
          elide: Text.ElideRight
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 38
          color: root.theme.surfaces.control
          border.color: responseInput.activeFocus
            ? root.theme.palette.accent
            : root.theme.palette.border
          border.width: root.theme.metrics.borderWidth
          radius: root.theme.metrics.radius

          TextInput {
            id: responseInput

            anchors.fill: parent
            anchors.margins: root.theme.metrics.controlPadding
            color: root.theme.palette.foreground
            selectionColor: root.theme.palette.accent
            selectedTextColor: root.theme.surfaces.popup
            font.family: root.theme.typography.monoFamily
            font.pixelSize: root.theme.typography.bodySize
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
        spacing: root.theme.polkit.spacing

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
