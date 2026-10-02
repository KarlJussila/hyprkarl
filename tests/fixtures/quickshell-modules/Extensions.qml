import QtQuick
import Quickshell
import Quickshell.Io
import ui.modal

Scope {
  id: root

  required property var context
  property int modalLoads: 0
  property int modalUnloads: 0

  Modal {
    context: root.context
    name: "user.fixture"
    title: "Personal modal"
    subtitle: "Loaded through the public module"
    preferredWidth: 480
    preferredHeight: 320

    body: Component {
      Item {
        Component.onCompleted: root.modalLoads++
        Component.onDestruction: root.modalUnloads++
      }
    }
  }

  IpcHandler {
    target: "userTest"

    function snapshot(): string {
      return JSON.stringify({
        "configuration": root.context.configuration.bar.edge,
        "fixture": root.context.settings.fixture,
        "themeForeground": String(root.context.theme.palette.foreground),
        "name": root.context.surfaceName,
        "output": root.context.surfaceOutput,
        "parameters": root.context.surfaceParameters,
        "modalLoads": root.modalLoads,
        "modalUnloads": root.modalUnloads
      })
    }

    function open(name: string, output: string, section: string): bool {
      return root.context.openSurface(name, output, { "section": section })
    }

    function replace(name: string, output: string, section: string): bool {
      return root.context.replaceSurface(name, output, { "section": section })
    }

    function push(name: string, output: string, section: string): bool {
      return root.context.pushSurface(name, output, { "section": section })
    }

    function toggle(name: string, output: string, section: string): bool {
      return root.context.toggleSurface(name, output, { "section": section })
    }

    function close(): void {
      root.context.closeSurface()
    }

    function back(): bool {
      return root.context.backSurface()
    }
  }
}
