pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Bluetooth
import "../../components"

PanelRow {
  id: root

  required property var device

  icon: deviceIcon(device.icon)
  title: device.name || device.deviceName || device.address
  detail: deviceDetail()
  selected: device.connected
  busy: device.pairing
    || device.state === BluetoothDeviceState.Connecting
    || device.state === BluetoothDeviceState.Disconnecting
  enabled: !device.blocked
  action: () => activateDevice()

  function deviceIcon(iconName: string): string {
    const name = iconName.toLowerCase()
    if (name.includes("head") || name.includes("audio")) return "󰋋"
    if (name.includes("keyboard")) return "󰌌"
    if (name.includes("mouse")) return "󰍽"
    if (name.includes("phone")) return "󰄜"
    if (name.includes("game")) return "󰊴"
    return "󰂯"
  }

  function batteryDetail(): string {
    return device.batteryAvailable ? ` · ${Math.round(device.battery * 100)}%` : ""
  }

  function deviceDetail(): string {
    if (device.blocked) return "blocked"
    if (device.pairing) return "pairing"
    if (device.state === BluetoothDeviceState.Connecting) return "connecting"
    if (device.state === BluetoothDeviceState.Disconnecting) return "disconnecting"
    if (device.connected) return `connected${batteryDetail()}`
    return device.paired ? "paired" : "available"
  }

  function activateDevice(): void {
    if (device.pairing) {
      device.cancelPair()
    } else if (device.state === BluetoothDeviceState.Connecting
      || device.state === BluetoothDeviceState.Disconnecting) {
      return
    } else if (device.connected) {
      device.disconnect()
    } else if (device.paired) {
      device.connect()
    } else {
      device.pair()
    }
  }
}
