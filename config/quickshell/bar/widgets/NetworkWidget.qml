pragma ComponentBehavior: Bound

import QtQuick
import "../../modules/network"
import "../../ui/controls"

ShellButton {
  id: root

  required property string widgetId
  required property var config
  required property var systemState

  readonly property var connectedNetwork: NetworkState.connectedNetwork
  readonly property bool panelOpen: panelHost
    ? panelHost.activeId === widgetId
    : false

  text: !NetworkState.wifiDevice || !NetworkState.wifiHardwareEnabled || !NetworkState.wifiEnabled
    ? "󰤭"
    : connectedNetwork ? signalIcon(connectedNetwork.signalStrength) : "󰤯"
  tooltip: !NetworkState.wifiDevice || !NetworkState.wifiHardwareEnabled
    ? "Wi-Fi unavailable" : !NetworkState.wifiEnabled ? "Wi-Fi off"
    : connectedNetwork ? connectedNetwork.name : "Not connected"
  tooltipSuppressed: panelOpen
  onPrimary: panelHost
    ? () => panelHost.toggle(widgetId, root, panelComponent)
    : null
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
