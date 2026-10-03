pragma Singleton

import QtQml
import Quickshell
import Quickshell.Hyprland

// Which monitor shell surfaces open on.
QtObject {
  function focusedName(): string {
    return Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? ""
  }

  // The named screen while it is connected, otherwise the first one.
  function resolve(name: string): string {
    return Quickshell.screens.some(screen => screen.name === name)
      ? name
      : Quickshell.screens[0]?.name ?? ""
  }
}
