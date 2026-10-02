import QtQuick
import Quickshell

Scope {
  id: root

  required property var shellConfig
  required property var theme
  required property var overlayState

  readonly property var item: moduleLoader.item
  readonly property var context: userContext

  property QtObject userContext: QtObject {
    id: userContext

    readonly property var configuration: root.shellConfig.values
    readonly property var settings: root.shellConfig.userRoot.settings
    readonly property var theme: root.theme
    readonly property var outputs: Quickshell.screens
    readonly property string overlayName: root.overlayState.activeSurface
    readonly property string overlayOutput: root.overlayState.screenName
    readonly property var overlayValues: root.overlayState.parameters
    readonly property int overlayRevision: root.overlayState.openRevision

    function openOverlay(name: string, output: string, values: var): bool {
      return root.overlayState.open(name, output, values)
    }

    function replaceOverlay(name: string, output: string, values: var): bool {
      return root.overlayState.replace(name, output, values)
    }

    function pushOverlay(name: string, output: string, values: var): bool {
      return root.overlayState.push(name, output, values)
    }

    function toggleOverlay(name: string, output: string, values: var): bool {
      return root.overlayState.toggle(name, output, values)
    }

    function closeOverlay(): void {
      root.overlayState.closeCurrent()
    }

    function backOverlay(): bool {
      return root.overlayState.back()
    }
  }

  property Loader moduleLoader: Loader {
    id: moduleLoader
    active: false

    onStatusChanged: {
      if (status === Loader.Error) {
        console.warn("User QML root failed to load '" + root.source + "'")
      }
    }
  }

  function load(): void {
    moduleLoader.active = false
    if (!theme.ready || source.length === 0) {
      return
    }

    moduleLoader.setSource(
      Paths.userUrl("custom/" + source),
      { "context": userContext }
    )
    moduleLoader.active = true
  }

  function notificationPosition(outputName: string): var {
    const loaded = item
    if (loaded === null
        || typeof loaded.notificationPosition !== "function") {
      return null
    }
    return loaded.notificationPosition(outputName)
  }

  readonly property string source: shellConfig.userRoot.source
  onSourceChanged: load()

  Connections {
    target: root.theme

    function onReadyChanged(): void { root.load() }
  }

  Component.onCompleted: load()
}
