pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../components"

Item {
  id: root

  required property var theme
  required property var config
  required property bool active

  readonly property var adapter: BluetoothState.adapter
  readonly property var sortedDevices: BluetoothState.devices.slice().sort((left, right) => {
    return (left.name || left.deviceName || left.address).localeCompare(
      right.name || right.deviceName || right.address
    )
  })
  readonly property var connectedDevices: sortedDevices.filter(device => device.connected)
  readonly property var pairedDevices: sortedDevices.filter(device => device.paired && !device.connected)
  readonly property var availableDevices: sortedDevices.filter(device => !device.paired)

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

  onActiveChanged: BluetoothState.requestDiscovery(root, active)
  Component.onCompleted: BluetoothState.requestDiscovery(root, active)
  Component.onDestruction: BluetoothState.requestDiscovery(root, false)

  Column {
    id: content

    width: parent.width
    spacing: root.theme.panelSpacing

    PanelHeader {
      width: parent.width
      theme: root.theme
      title: "Bluetooth"
      subtitle: root.adapterSubtitle()
    }

    PanelRow {
      visible: root.adapter !== null
      width: parent.width
      theme: root.theme
      icon: root.adapter?.enabled ? "󰂯" : "󰂲"
      title: "Bluetooth"
      detail: root.adapter?.enabled ? "on" : "off"
      selected: root.adapter?.enabled ?? false
      busy: root.adapter?.state === BluetoothAdapterState.Enabling
        || root.adapter?.state === BluetoothAdapterState.Disabling
      enabled: root.adapter?.state !== BluetoothAdapterState.Blocked
      action: root.adapter ? () => root.adapter.enabled = !root.adapter.enabled : null
    }

    Text {
      visible: root.adapter === null
      width: parent.width
      text: "No Bluetooth adapter is available."
      color: root.theme.text
      opacity: 0.65
      wrapMode: Text.Wrap
      font.family: root.theme.fontUi
      font.pixelSize: root.theme.fontSize
    }

    PanelSectionLabel {
      visible: root.connectedDevices.length > 0
      theme: root.theme
      text: "Connected"
    }

    Repeater {
      model: root.connectedDevices

      BluetoothDeviceRow {
        required property var modelData
        width: parent.width
        theme: root.theme
        device: modelData
      }
    }

    PanelSectionLabel {
      visible: root.pairedDevices.length > 0
      theme: root.theme
      text: "Paired devices"
    }

    Repeater {
      model: root.pairedDevices

      BluetoothDeviceRow {
        required property var modelData
        width: parent.width
        theme: root.theme
        device: modelData
      }
    }

    PanelSectionLabel {
      visible: root.adapter?.enabled ?? false
      theme: root.theme
      text: root.adapter?.discovering ? "Available devices · scanning" : "Available devices"
    }

    Text {
      visible: root.adapter?.enabled && root.availableDevices.length === 0
      width: parent.width
      text: "No nearby devices found yet."
      color: root.theme.text
      opacity: 0.65
      wrapMode: Text.Wrap
      font.family: root.theme.fontUi
      font.pixelSize: root.theme.fontSize
    }

    Repeater {
      model: root.adapter?.enabled ? root.availableDevices : []

      BluetoothDeviceRow {
        required property var modelData
        width: parent.width
        theme: root.theme
        device: modelData
      }
    }

    PanelAction {
      visible: root.config.secondaryCommand?.length > 0
      width: parent.width
      theme: root.theme
      icon: "󰒓"
      text: "Open Bluetooth settings"
      action: () => Quickshell.execDetached(["bash", "-lc", root.config.secondaryCommand])
    }
  }
}
