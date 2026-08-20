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

  function toggle(surface: string, screen: string): bool {
    if (activeSurface === surface && screenName === screen) {
      close(surface)
      return true
    }
    return open(surface, screen, {})
  }

  function toggleFocused(surface: string): bool {
    return toggle(surface, focusedScreenName())
  }

  function close(surface: string): void {
    if (activeSurface !== surface) return
    activeSurface = ""
    screenName = ""
    parameters = ({})
  }
}
