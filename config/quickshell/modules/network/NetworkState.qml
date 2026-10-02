pragma Singleton

import QtQml
import Quickshell.Networking

QtObject {
  id: root

  readonly property var wifiDevice: Networking.devices.values.find(device => device.type === DeviceType.Wifi) ?? null
  readonly property var connectedNetwork: wifiDevice?.networks.values.find(network => network.connected) ?? null
  readonly property var networks: wifiDevice?.networks.values ?? []
  readonly property bool wifiEnabled: Networking.wifiEnabled
  readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled
  property var scanOwners: []
  property var scanningDevice: null

  function requestScanning(owner, requested: bool): void {
    const owners = scanOwners.filter(entry => entry !== owner)
    if (requested) owners.push(owner)
    scanOwners = owners
    updateScanning()
  }

  function updateScanning(): void {
    const nextDevice = scanOwners.length > 0 && Networking.wifiEnabled ? wifiDevice : null
    if (scanningDevice && scanningDevice !== nextDevice) scanningDevice.scannerEnabled = false
    scanningDevice = nextDevice
    if (scanningDevice) scanningDevice.scannerEnabled = true
  }

  onWifiDeviceChanged: updateScanning()

  property Connections networkingConnections: Connections {
    target: Networking
    function onWifiEnabledChanged(): void { root.updateScanning() }
  }
}
