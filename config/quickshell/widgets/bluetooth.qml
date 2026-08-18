pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import "../features/bluetooth"

ShellButton {
  id: root

  required property string widgetId
  required property var config
  required property var systemState

  readonly property var adapter: BluetoothState.adapter
  readonly property int connectedCount: BluetoothState.devices.filter(device => device.connected).length
  readonly property bool panelOpen: panelHost.activeId === widgetId

  implicitWidth: theme.widgetPadding * 2 + 8
  text: !adapter?.enabled ? "󰂲" : connectedCount > 0 ? "󰂱" : "󰂯"
  tooltip: !adapter?.enabled ? "Bluetooth off" : connectedCount > 0 ? `${connectedCount} Bluetooth device${connectedCount === 1 ? "" : "s"} connected` : "Bluetooth on"
  tooltipSuppressed: panelOpen
  onPrimary: () => panelHost.toggle(widgetId, root, panelComponent)
  secondaryCommand: config.secondaryCommand

  Component {
    id: panelComponent

    BluetoothPanel {
      theme: root.theme
      config: root.config
      active: root.panelOpen
    }
  }
}
