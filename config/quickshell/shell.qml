pragma ComponentBehavior: Bound

import Quickshell
import "config"
import "state"

ShellRoot {
  ShellConfig { id: configObject }
  Theme { id: themeObject }
  SystemState { id: stateObject }

  Variants {
    model: configObject.ready && themeObject.ready ? Quickshell.screens : []

    Bar {
      required property var modelData

      screen: modelData
      shellConfig: configObject
      theme: themeObject
      systemState: stateObject
    }
  }
}
