pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Bluetooth
import "../../components"

Item {
  id: root

  required property var theme
  required property var config
  required property bool active

  signal externalCommandRequested(string command)

  readonly property real preferredWidth: theme.panelWidth
  readonly property var adapter: BluetoothState.adapter
  readonly property var sortedDevices: BluetoothState.devices.slice().sort((left, right) => {
    return (left.name || left.deviceName || left.address).localeCompare(
      right.name || right.deviceName || right.address
    )
  })
  readonly property var connectedDevices: sortedDevices.filter(device => device.connected)
  readonly property var pairedDevices: sortedDevices.filter(device => device.paired && !device.connected)
  readonly property var availableDevices: sortedDevices.filter(device => !device.paired)
  property bool discoveryRequested: false

  implicitWidth: parent?.width ?? 0
  implicitHeight: content.implicitHeight

  function adapterSubtitle(): string {
    if (!adapter) return "No Bluetooth adapter"
    if (adapter.state === BluetoothAdapterState.Blocked) return "Bluetooth is blocked"
    if (adapter.state === BluetoothAdapterState.Enabling) return "Turning Bluetooth on"
    if (adapter.state === BluetoothAdapterState.Disabling) return "Turning Bluetooth off"
    if (!adapter.enabled) return "Bluetooth is off"
    if (connectedDevices.length > 0) {
      return `${connectedDevices.length} device${connectedDevices.length === 1 ? "" : "s"} connected`
    }
    return "Not connected"
  }

  function startDiscovery(): void {
    discoveryRequested = true
    BluetoothState.requestDiscovery(root, true)
  }

  onActiveChanged: {
    if (active) return
    discoveryRequested = false
    BluetoothState.requestDiscovery(root, false)
  }
  Component.onDestruction: BluetoothState.requestDiscovery(root, false)

  PanelLayout {
    id: content

    width: parent.width
    theme: root.theme
    title: "Bluetooth"
    subtitle: root.adapterSubtitle()
    action: root.config.secondaryCommand?.length > 0
      ? () => root.externalCommandRequested(root.config.secondaryCommand)
      : null

    PanelRow {
      visible: root.adapter !== null
      width: parent.width
      theme: root.theme
      navigationSection: "adapter"
      icon: root.adapter?.enabled ? "󰂯" : "󰂲"
      title: "Bluetooth"
      switchVisible: true
      switchActive: root.adapter?.enabled ?? false
      busy: root.adapter?.state === BluetoothAdapterState.Enabling
        || root.adapter?.state === BluetoothAdapterState.Disabling
      enabled: root.adapter?.state !== BluetoothAdapterState.Blocked
      action: root.adapter ? () => root.adapter.enabled = !root.adapter.enabled : null
    }

    Text {
      visible: root.adapter === null
      width: parent.width
      text: "No Bluetooth adapter is available."
      color: root.theme.panelForeground
      opacity: 0.65
      wrapMode: Text.Wrap
      font.family: root.theme.panelFont
      font.pixelSize: root.theme.panelFontSize
    }

    PanelSectionLabel {
      visible: root.connectedDevices.length > 0
      theme: root.theme
      navigationSection: "connected"
      text: "Connected"
    }

    Repeater {
      model: root.connectedDevices

      BluetoothDeviceRow {
        required property var modelData
        width: parent.width
        theme: root.theme
        device: modelData
        navigationSection: "connected"
      }
    }

    PanelSectionLabel {
      visible: root.pairedDevices.length > 0
      theme: root.theme
      navigationSection: "paired"
      text: "Paired devices"
    }

    Repeater {
      model: root.pairedDevices

      BluetoothDeviceRow {
        required property var modelData
        width: parent.width
        theme: root.theme
        device: modelData
        navigationSection: "paired"
      }
    }

    PanelSectionLabel {
      visible: root.discoveryRequested && (root.adapter?.enabled ?? false)
      theme: root.theme
      navigationSection: "available"
      text: root.adapter?.discovering ? "Available devices · scanning" : "Available devices"
    }

    PanelAction {
      visible: !root.discoveryRequested && (root.adapter?.enabled ?? false)
      width: parent.width
      theme: root.theme
      navigationSection: "available"
      icon: "󰍉"
      text: "Scan for devices"
      action: () => root.startDiscovery()
    }

    Text {
      visible: root.discoveryRequested
        && root.adapter?.enabled
        && root.availableDevices.length === 0
      width: parent.width
      text: "No nearby devices found yet."
      color: root.theme.panelForeground
      opacity: 0.65
      wrapMode: Text.Wrap
      font.family: root.theme.panelFont
      font.pixelSize: root.theme.panelFontSize
    }

    Repeater {
      model: root.discoveryRequested && root.adapter?.enabled
        ? root.availableDevices
        : []

      BluetoothDeviceRow {
        required property var modelData
        width: parent.width
        theme: root.theme
        device: modelData
        navigationSection: "available"
      }
    }
  }
}
