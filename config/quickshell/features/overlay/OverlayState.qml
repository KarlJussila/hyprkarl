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

  function focusedScreenName(): string {
    return Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? ""
  }

  function open(surface: string, screen: string, nextParameters: var): bool {
    if (activeSurface.length > 0) return false
    return replace(surface, screen, nextParameters)
  }

  function replace(surface: string, screen: string, nextParameters: var): bool {
    if (surface.length === 0 || screen.length === 0) return false
    parameters = nextParameters ?? ({})
    screenName = screen
    activeSurface = surface
    openRevision++
    return true
  }

  function openFocused(surface: string): bool {
    return open(surface, focusedScreenName(), {})
  }

  function replaceFocused(surface: string, nextParameters: var): bool {
    return replace(surface, focusedScreenName(), nextParameters)
  }

  function toggle(surface: string, screen: string, nextParameters: var): bool {
    if (activeSurface === surface && screenName === screen) {
      close(surface)
      return true
    }
    return replace(surface, screen, nextParameters)
  }

  function toggleFocused(surface: string): bool {
    return toggle(surface, focusedScreenName(), {})
  }

  function close(surface: string): void {
    if (activeSurface !== surface) return
    activeSurface = ""
    screenName = ""
    parameters = ({})
  }

  function closeCurrent(): void {
    if (activeSurface.length > 0) close(activeSurface)
  }
}
