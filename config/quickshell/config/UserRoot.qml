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

  property Loader moduleLoader: Loader { id: moduleLoader }

  // setSource, not a source binding, so the root's required context is set
  // as it is created.
  function load(): void {
    moduleLoader.setSource(url, { "context": userContext })
  }

  function notificationPosition(outputName: string): var {
    return item?.notificationPosition?.(outputName) ?? null
  }

  readonly property string source: shellConfig.userRoot.source
  readonly property string url: source.length > 0
    ? Paths.userUrl("custom/" + source) : ""
  onUrlChanged: load()
  Component.onCompleted: load()
}
