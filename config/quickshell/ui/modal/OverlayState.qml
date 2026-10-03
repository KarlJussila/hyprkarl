pragma Singleton

import QtQml
import Quickshell
import Quickshell.Hyprland

QtObject {
  id: root

  property string activeSurface: ""
  property string screenName: ""
  property var parameters: ({})
  property int openRevision: 0
  property var returnRequests: []

  function focusedScreenName(): string {
    return Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? ""
  }

  function open(surface: string, screen: string, nextParameters: var): bool {
    if (activeSurface.length > 0) return false
    return replace(surface, screen, nextParameters)
  }

  function setRequest(surface: string, screen: string, nextParameters: var): bool {
    if (surface.length === 0 || screen.length === 0) return false
    parameters = nextParameters ?? ({})
    screenName = screen
    activeSurface = surface
    openRevision++
    return true
  }

  function replace(surface: string, screen: string, nextParameters: var): bool {
    returnRequests = []
    return setRequest(surface, screen, nextParameters)
  }

  function push(surface: string, screen: string, nextParameters: var): bool {
    if (surface.length === 0 || screen.length === 0) return false
    if (activeSurface.length > 0) {
      returnRequests = returnRequests.concat([{
        "surface": activeSurface,
        "screen": screenName,
        "parameters": parameters
      }])
    }
    return setRequest(surface, screen, nextParameters)
  }

  function back(): bool {
    if (returnRequests.length === 0) return false
    const previous = returnRequests[returnRequests.length - 1]
    returnRequests = returnRequests.slice(0, -1)
    return setRequest(previous.surface, previous.screen, previous.parameters)
  }

  function toggle(surface: string, screen: string, nextParameters: var): bool {
    if (activeSurface === surface && screenName === screen) {
      close(surface)
      return true
    }
    return replace(surface, screen, nextParameters)
  }

  function close(surface: string): void {
    if (activeSurface !== surface) return
    returnRequests = []
    activeSurface = ""
    screenName = ""
    parameters = ({})
  }

  function closeCurrent(): void {
    if (activeSurface.length > 0) close(activeSurface)
  }
}
