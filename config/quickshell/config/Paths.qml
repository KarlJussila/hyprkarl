pragma Singleton

import QtQml
import Quickshell

QtObject {
  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME")
    ?? Quickshell.env("HOME") + "/.config"
  readonly property string userRoot: configHome + "/quickshell"
  readonly property string defaultsRoot: Quickshell.env("HYPRKARL_PATH") + "/defaults"
  readonly property string stateHome: (Quickshell.env("XDG_STATE_HOME")
    ?? Quickshell.env("HOME") + "/.local/state") + "/hyprkarl"

  function userPath(path: string): string {
    return userRoot + "/" + path
  }

  function userUrl(path: string): string {
    return "file://" + userPath(path)
  }
}
