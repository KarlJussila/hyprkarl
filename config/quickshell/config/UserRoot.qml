import QtQuick
import Quickshell

Scope {
  id: root

  required property var shellConfig
  required property var theme

  readonly property var item: moduleLoader.item

  property QtObject userContext: QtObject {
    id: userContext

    readonly property var configuration: root.shellConfig.values
    readonly property var settings: root.shellConfig.userRootSettings
    readonly property var theme: root.theme
  }

  property Loader moduleLoader: Loader {
    id: moduleLoader
    active: false

    onStatusChanged: {
      if (status === Loader.Error) {
        console.warn("User QML root failed to load '"
          + root.shellConfig.userRootSource + "'")
      }
    }
  }

  function load(): void {
    moduleLoader.active = false
    if (!shellConfig.ready || !theme.ready
        || shellConfig.userRootSource.length === 0) {
      return
    }

    moduleLoader.setSource(
      Paths.userUrl("quickshell/" + shellConfig.userRootSource),
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

  Connections {
    target: root.shellConfig

    function onReadyChanged(): void { root.load() }
    function onUserRootSourceChanged(): void { root.load() }
  }

  Connections {
    target: root.theme

    function onReadyChanged(): void { root.load() }
  }

  Component.onCompleted: load()
}
