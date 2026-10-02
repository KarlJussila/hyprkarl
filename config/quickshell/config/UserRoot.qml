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
    readonly property string surfaceName: root.overlayState.activeSurface
    readonly property string surfaceOutput: root.overlayState.screenName
    readonly property var surfaceParameters: root.overlayState.parameters

    function openSurface(name: string, output: string, parameters: var): bool {
      return root.overlayState.open(name, output, parameters)
    }

    function replaceSurface(name: string, output: string, parameters: var): bool {
      return root.overlayState.replace(name, output, parameters)
    }

    function pushSurface(name: string, output: string, parameters: var): bool {
      return root.overlayState.push(name, output, parameters)
    }

    function toggleSurface(name: string, output: string, parameters: var): bool {
      return root.overlayState.toggle(name, output, parameters)
    }

    function closeSurface(): void {
      root.overlayState.closeCurrent()
    }

    function backSurface(): bool {
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

  // The initial change signal and onCompleted can both arrive at startup;
  // loading an already-loaded URL again would create a second root.
  function load(): void {
    if (moduleLoader.source.toString() === url) return
    moduleLoader.active = false
    if (url.length === 0) {
      moduleLoader.source = ""
      return
    }
    moduleLoader.setSource(url, { "context": userContext })
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
  readonly property string url: theme.ready && source.length > 0
    ? Paths.userUrl("custom/" + source) : ""
  onUrlChanged: load()
  Component.onCompleted: load()
}
