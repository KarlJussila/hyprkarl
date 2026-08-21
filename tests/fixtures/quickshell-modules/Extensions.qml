import QtQml
import Quickshell
import Quickshell.Io

Scope {
  id: root

  required property var context

  IpcHandler {
    target: "userTest"

    function snapshot(): string {
      return JSON.stringify({
        "configuration": root.context.configuration.version,
        "fixture": root.context.settings.fixture,
        "outputCount": root.context.outputs.length,
        "themeForeground": String(root.context.theme.foreground),
        "name": root.context.overlayName,
        "output": root.context.overlayOutput,
        "values": root.context.overlayValues,
        "revision": root.context.overlayRevision
      })
    }

    function open(name: string, output: string, section: string): bool {
      return root.context.openOverlay(name, output, { "section": section })
    }

    function replace(name: string, output: string, section: string): bool {
      return root.context.replaceOverlay(name, output, { "section": section })
    }

    function toggle(name: string, output: string, section: string): bool {
      return root.context.toggleOverlay(name, output, { "section": section })
    }

    function close(): void {
      root.context.closeOverlay()
    }
  }
}
