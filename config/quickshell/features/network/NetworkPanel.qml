pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking
import "../../components"

Item {
  id: root

  required property var theme
  required property var config
  required property bool active

  readonly property var wifiDevice: NetworkState.wifiDevice
  readonly property var connectedNetwork: NetworkState.connectedNetwork
  readonly property var sortedNetworks: NetworkState.networks.slice().sort((left, right) => {
    if (left.connected !== right.connected) return left.connected ? -1 : 1
    return right.signalStrength - left.signalStrength
  })
  property var passwordNetwork: null

  implicitWidth: parent?.width ?? 0
  implicitHeight: content.implicitHeight

  function signalIcon(strength: real): string {
    if (strength >= 0.75) return "󰤨"
    if (strength >= 0.5) return "󰤥"
    if (strength >= 0.25) return "󰤢"
    return "󰤟"
  }

  function choose(network): void {
    if (network.stateChanging) return
    if (network.connected) {
      network.disconnect()
    } else if (network.known || network.security === WifiSecurityType.Open) {
      network.connect()
    } else {
      passwordNetwork = network
    }
  }

  onActiveChanged: NetworkState.requestScanning(root, active)
  Component.onCompleted: NetworkState.requestScanning(root, active)
  Component.onDestruction: NetworkState.requestScanning(root, false)

  Column {
    id: content

    width: parent.width
    spacing: root.theme.panelSpacing

    PanelHeader {
      width: parent.width
      theme: root.theme
      title: "Network"
      subtitle: !Networking.wifiHardwareEnabled
        ? "Wi-Fi unavailable"
        : root.connectedNetwork
          ? `Connected to ${root.connectedNetwork.name}`
          : Networking.wifiEnabled ? "Not connected" : "Wi-Fi is off"
    }

    PanelRow {
      width: parent.width
      theme: root.theme
      icon: Networking.wifiEnabled ? "󰖩" : "󰖪"
      title: "Wi-Fi"
      detail: Networking.wifiEnabled ? "on" : "off"
      selected: Networking.wifiEnabled
      enabled: Networking.wifiHardwareEnabled
      action: () => Networking.wifiEnabled = !Networking.wifiEnabled
    }

    PanelRow {
      visible: root.connectedNetwork !== null
      width: parent.width
      theme: root.theme
      icon: root.connectedNetwork ? root.signalIcon(root.connectedNetwork.signalStrength) : ""
      title: root.connectedNetwork?.name ?? ""
      detail: root.connectedNetwork ? `${Math.round(root.connectedNetwork.signalStrength * 100)}%` : ""
      selected: true
      busy: root.connectedNetwork?.stateChanging ?? false
      action: root.connectedNetwork ? () => root.connectedNetwork.disconnect() : null
    }

    PanelSectionLabel {
      visible: Networking.wifiEnabled && root.wifiDevice !== null
      theme: root.theme
      text: root.wifiDevice?.scannerEnabled ? "Available networks · scanning" : "Available networks"
    }

    Text {
      visible: !Networking.wifiEnabled || root.wifiDevice === null || root.sortedNetworks.length === 0
      width: parent.width
      text: !Networking.wifiEnabled
        ? "Turn on Wi-Fi to view nearby networks."
        : root.wifiDevice === null ? "No Wi-Fi adapter is available." : "No networks found yet."
      color: root.theme.text
      opacity: 0.65
      wrapMode: Text.Wrap
      font.family: root.theme.fontUi
      font.pixelSize: root.theme.fontSize
    }

    Repeater {
      model: Networking.wifiEnabled ? root.sortedNetworks : []

      Item {
        id: networkEntry

        required property var modelData
        property string failure: ""
        readonly property bool enteringPassword: root.passwordNetwork === modelData

        width: parent.width
        implicitHeight: networkRow.implicitHeight + (enteringPassword ? passwordBox.implicitHeight + 4 : 0)

        onEnteringPasswordChanged: {
          if (enteringPassword) Qt.callLater(password.forceActiveFocus)
        }

        PanelRow {
          id: networkRow

          width: parent.width
          theme: root.theme
          icon: root.signalIcon(networkEntry.modelData.signalStrength)
          title: networkEntry.modelData.name
          detail: networkEntry.modelData.security === WifiSecurityType.Open
            ? `${Math.round(networkEntry.modelData.signalStrength * 100)}%`
            : `󰌾  ${Math.round(networkEntry.modelData.signalStrength * 100)}%`
          error: networkEntry.failure
          selected: networkEntry.modelData.connected
          busy: networkEntry.modelData.stateChanging
          action: () => {
            networkEntry.failure = ""
            root.choose(networkEntry.modelData)
          }
        }

        Rectangle {
          id: passwordBox

          anchors.top: networkRow.bottom
          anchors.topMargin: 4
          width: parent.width
          implicitHeight: 38
          visible: networkEntry.enteringPassword
          color: root.theme.background
          border.color: password.activeFocus ? root.theme.accent : root.theme.border
          border.width: root.theme.borderWidth
          radius: root.theme.radius

          Text {
            anchors.left: parent.left
            anchors.leftMargin: root.theme.widgetPadding
            anchors.verticalCenter: parent.verticalCenter
            visible: password.text.length === 0 && !password.activeFocus
            text: "Password"
            color: root.theme.text
            opacity: 0.5
            font.family: root.theme.fontUi
            font.pixelSize: root.theme.fontSize
          }

          TextInput {
            id: password

            anchors.fill: parent
            anchors.margins: root.theme.widgetPadding
            color: root.theme.text
            font.family: root.theme.fontMono
            font.pixelSize: root.theme.fontSize
            echoMode: TextInput.Password
            selectByMouse: true
            activeFocusOnTab: true
            clip: true
            Keys.onEscapePressed: event => {
              root.passwordNetwork = null
              text = ""
              event.accepted = true
            }
            onAccepted: {
              if (text.length === 0) return
              networkEntry.failure = ""
              networkEntry.modelData.connectWithPsk(text)
              text = ""
            }
          }
        }

        Connections {
          target: networkEntry.modelData

          function onConnectionFailed(reason): void {
            networkEntry.failure = ConnectionFailReason.toString(reason)
            if (reason === ConnectionFailReason.NoSecrets) root.passwordNetwork = networkEntry.modelData
          }

          function onConnectedChanged(): void {
            if (!networkEntry.modelData.connected) return
            networkEntry.failure = ""
            if (root.passwordNetwork === networkEntry.modelData) root.passwordNetwork = null
          }
        }
      }
    }

    PanelAction {
      visible: root.config.secondaryCommand?.length > 0
      width: parent.width
      theme: root.theme
      icon: "󰒓"
      text: "Open network settings"
      action: () => Quickshell.execDetached(["bash", "-lc", root.config.secondaryCommand])
    }
  }
}
