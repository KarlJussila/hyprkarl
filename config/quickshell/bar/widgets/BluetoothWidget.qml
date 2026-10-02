pragma ComponentBehavior: Bound

import QtQuick
import "../../modules/bluetooth"
import "../../ui/controls"

ShellButton {
  id: root

  required property string widgetId
  required property var config
  required property var systemState

  readonly property var adapter: BluetoothState.adapter
  readonly property int connectedCount: BluetoothState.devices.filter(device => device.connected).length
  readonly property bool panelOpen: panelHost
    ? panelHost.activeId === widgetId
    : false

  text: !adapter?.enabled ? "󰂲" : connectedCount > 0 ? "󰂱" : "󰂯"
  tooltip: !adapter?.enabled ? "Bluetooth off" : connectedCount > 0 ? `${connectedCount} Bluetooth device${connectedCount === 1 ? "" : "s"} connected` : "Bluetooth on"
  tooltipSuppressed: panelOpen
  onPrimary: panelHost
    ? () => panelHost.toggle(widgetId, root, panelComponent)
    : null
  secondaryCommand: config.secondaryCommand

  Component {
    id: panelComponent

    BluetoothPanel {
      theme: root.theme
      config: root.config
      active: root.panelOpen
      onExternalCommandRequested: command => root.launchPanelCommand(command)
    }
  }
}
