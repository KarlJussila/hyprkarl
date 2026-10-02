import QtQml
import Quickshell

JsonSettings {
  defaultPath: Quickshell.shellPath("../../defaults/shell.json")
  personalPath: Paths.userPath("settings/shell.json")

  readonly property var bar: values.bar
  readonly property var osd: values.osd
  readonly property var notifications: values.notifications
  readonly property var userRoot: values.userRoot

  // Module choices latch at startup; changing them needs hk-shell restart.
  property var modules: ({})
  Component.onCompleted: modules = values.modules
}
