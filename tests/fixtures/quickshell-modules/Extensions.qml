import QtQuick
import Quickshell
import Quickshell.Io
import ui.modal

Scope {
  id: root

  required property var context
  property int modalLoads: 0

  Modal {
    context: root.context
    name: "user.fixture"
    title: "Personal modal"
    subtitle: "Loaded through the public module"
    preferredWidth: 480
    preferredHeight: 320

    body: Component {
      Item { Component.onCompleted: root.modalLoads++ }
    }
  }

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
        "revision": root.context.overlayRevision,
        "modalLoads": root.modalLoads
      })
    }

    function open(name: string, output: string, section: string): bool {
      return root.context.openOverlay(name, output, { "section": section })
    }

    function replace(name: string, output: string, section: string): bool {
      return root.context.replaceOverlay(name, output, { "section": section })
    }

    function push(name: string, output: string, section: string): bool {
      return root.context.pushOverlay(name, output, { "section": section })
    }

    function toggle(name: string, output: string, section: string): bool {
      return root.context.toggleOverlay(name, output, { "section": section })
    }

    function close(): void {
      root.context.closeOverlay()
    }

    function back(): bool {
      return root.context.backOverlay()
    }
  }
}
