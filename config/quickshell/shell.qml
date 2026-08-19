//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import Quickshell
import "config"
import "features/menu"
import "features/osd"
import "state"

ShellRoot {
  ShellConfig { id: configObject }
  Theme { id: themeObject }
  SystemState { id: stateObject }
  OsdState {
    id: osdStateObject
    shellConfig: configObject
  }

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

  Variants {
    model: configObject.ready && themeObject.ready ? Quickshell.screens : []

    OsdWindow {
      required property var modelData

      output: modelData
      osdState: osdStateObject
      shellConfig: configObject
      theme: themeObject
    }
  }

  Variants {
    model: configObject.ready && themeObject.ready && MenuState.ready
      ? Quickshell.screens
      : []

    MenuWindow {
      required property var modelData

      output: modelData
      theme: themeObject
    }
  }
}
