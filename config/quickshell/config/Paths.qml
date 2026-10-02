pragma Singleton

import QtQml
import Quickshell

QtObject {
  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME")
    ?? Quickshell.env("HOME") + "/.config"
  readonly property string userRoot: configHome + "/quickshell"

  function userPath(path: string): string {
    return userRoot + "/" + path
  }

  function userUrl(path: string): string {
    return "file://" + userPath(path)
  }
}
