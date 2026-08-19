pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import "../features/network"

ShellButton {
  id: root

  required property string widgetId
  required property var config
  required property var systemState

  readonly property var connectedNetwork: NetworkState.connectedNetwork
  readonly property bool panelOpen: panelHost.activeId === widgetId

  text: !NetworkState.wifiDevice || !NetworkState.wifiHardwareEnabled || !NetworkState.wifiEnabled
    ? "󰤭"
    : connectedNetwork ? signalIcon(connectedNetwork.signalStrength) : "󰤯"
  tooltip: !NetworkState.wifiDevice || !NetworkState.wifiHardwareEnabled
    ? "Wi-Fi unavailable" : !NetworkState.wifiEnabled ? "Wi-Fi off"
    : connectedNetwork ? connectedNetwork.name : "Not connected"
  tooltipSuppressed: panelOpen
  onPrimary: () => panelHost.toggle(widgetId, root, panelComponent)
  secondaryCommand: config.secondaryCommand

  function signalIcon(strength: real): string {
    if (strength >= 0.75) return "󰤨"
    if (strength >= 0.5) return "󰤥"
    if (strength >= 0.25) return "󰤢"
    return "󰤟"
  }

  Component {
    id: panelComponent

    NetworkPanel {
      theme: root.theme
      config: root.config
      active: root.panelOpen
      onExternalCommandRequested: command => root.launchPanelCommand(command)
    }
  }
}
