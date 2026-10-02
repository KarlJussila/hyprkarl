import QtQuick
import Quickshell
import "../../config"
import "../../ui/controls"

Item {
  id: root

  required property string widgetId
  required property var config
  required property string edge
  required property var barWindow
  required property var theme
  required property var systemState
  required property var panelHost

  readonly property var loadedItem: moduleLoader.item
  readonly property string tooltip: loadedItem && "tooltip" in loadedItem
    ? loadedItem.tooltip
    : ""
  readonly property bool tooltipSuppressed:
    loadedItem && "tooltipSuppressed" in loadedItem
      ? loadedItem.tooltipSuppressed
      : false
  property int hostMainPaddingOffset:
    loadedItem && "hostMainPaddingOffset" in loadedItem
      ? loadedItem.hostMainPaddingOffset
      : 0

  visible: moduleLoader.status === Loader.Ready
    && (!("widgetVisible" in loadedItem) || loadedItem.widgetVisible)
  implicitWidth: loadedItem?.implicitWidth ?? 0
  implicitHeight: loadedItem?.implicitHeight ?? 0

  QtObject {
    id: widgetContext

    readonly property string widgetId: root.widgetId
    readonly property string edge: root.edge
    readonly property string orientation: "horizontal"
    readonly property string output: root.barWindow.screen.name
    readonly property var settings: root.config.settings ?? ({})
    readonly property var theme: root.theme
    readonly property var barWindow: root.barWindow

    function runCommand(command: string): void {
      Quickshell.execDetached([
        "uwsm-app", "--", "env", "HYPRKARL_OUTPUT=" + output,
        "bash", "-c", command
      ])
    }

    function togglePanel(trigger: Item, content: Component): void {
      if (root.panelHost) root.panelHost.toggle(widgetId, trigger, content)
    }

    function closePanel(): void {
      if (root.panelHost) root.panelHost.close()
    }

    function launchPanelCommand(command: string): void {
      closePanel()
      runCommand(command)
    }
  }

  Loader {
    id: moduleLoader

    anchors.fill: parent

    onStatusChanged: {
      if (status === Loader.Error) {
        console.warn("User QML widget '" + root.widgetId
          + "' failed to load '" + root.config.source + "'")
      }
    }
  }

  HoverHandler { id: hover }

  ShellTooltip {
    anchorItem: root
    anchorWindow: root.barWindow
    edge: root.edge
    text: root.tooltip
    theme: root.theme
    requested: hover.hovered && !root.tooltipSuppressed && root.tooltip.length > 0
  }

  Component.onCompleted: {
    moduleLoader.setSource(
      Paths.userUrl("custom/modules/" + root.config.source),
      { "context": widgetContext }
    )
  }
}
