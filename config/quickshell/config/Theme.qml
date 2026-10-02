import QtQuick
import Quickshell
import Quickshell.Io

// The active theme's quickshell.json. The compiler supplies every value, so
// consumers read groups directly: theme.panel.padding, theme.palette.accent.
QtObject {
  id: root

  // Bindings, not load handlers: the first read loads the files synchronously,
  // so consumers built at startup (the lock surface) never see an empty theme.
  readonly property var selection: JSON.parse(selector.text())
  readonly property string activeName: selection.name
  readonly property var values: JSON.parse(source.text())
  readonly property bool ready: Object.keys(values).length > 0

  readonly property var palette: values.palette
  readonly property var surfaces: values.surfaces
  readonly property var typography: values.typography
  readonly property var metrics: values.metrics
  readonly property var bar: values.bar
  readonly property var panel: values.panel
  readonly property var tooltip: values.tooltip
  readonly property var osd: values.osd
  readonly property var notification: values.notification
  readonly property var polkit: values.polkit
  readonly property var lock: values.lock
  readonly property var menu: values.menu
  readonly property var applicationPicker: values.applicationPicker
  readonly property var calculator: values.calculator
  readonly property var wallpaperPicker: values.wallpaperPicker
  readonly property var displayArrangement: values.displayArrangement
  // `switch` is reserved in QML, so this group cannot use its own name.
  readonly property var switchAppearance: values["switch"]

  readonly property string stateHome: (Quickshell.env("XDG_STATE_HOME")
    ?? Quickshell.env("HOME") + "/.local/state") + "/hyprkarl"

  property FileView selector: FileView {
    path: root.stateHome + "/current/theme.json"
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
  }

  property FileView source: FileView {
    path: root.stateHome + "/themes/" + root.selection.artifact + "/quickshell.json"
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
  }
}
