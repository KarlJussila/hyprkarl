pragma Singleton

import QtQml
import Quickshell.Bluetooth

QtObject {
  id: root

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var devices: adapter?.devices.values ?? []
  property var discoveryOwners: []
  property var discoveryAdapter: null
  property bool ownsDiscovery: false

  function requestDiscovery(owner, requested: bool): void {
    const owners = discoveryOwners.filter(entry => entry !== owner)
    if (requested) owners.push(owner)
    discoveryOwners = owners
    updateDiscovery()
  }

  function stopOwnedDiscovery(): void {
    if (discoveryAdapter && ownsDiscovery && discoveryAdapter.discovering) {
      discoveryAdapter.discovering = false
    }
    discoveryAdapter = null
    ownsDiscovery = false
  }

  function updateDiscovery(): void {
    const nextAdapter = discoveryOwners.length > 0 && adapter?.enabled ? adapter : null

    if (discoveryAdapter === nextAdapter && ownsDiscovery) return
    if (discoveryAdapter !== nextAdapter) stopOwnedDiscovery()
    if (!nextAdapter) return

    discoveryAdapter = nextAdapter
    if (!nextAdapter.discovering) {
      nextAdapter.discovering = true
      ownsDiscovery = true
    }
  }

  onAdapterChanged: updateDiscovery()

  property Connections adapterConnections: Connections {
    target: root.adapter

    function onEnabledChanged(): void { root.updateDiscovery() }
  }
}
