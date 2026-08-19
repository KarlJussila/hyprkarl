import "../components"
import "../features/menu"

ShellButton {
  required property string widgetId
  required property var config
  required property var systemState

  text: config.icon
  tooltip: "Main menu"
  onPrimary: () => {
    panelHost.close()
    MenuState.toggleForScreen(barWindow.screen.name, MenuState.rootMenu)
  }
}
