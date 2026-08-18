import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property var values: ({})

  readonly property color text: values.text
  readonly property color surface: values.surface
  readonly property color background: values.background
  readonly property color accent: values.accent
  readonly property color border: values.border
  readonly property color error: values.error
  readonly property color batteryLow: values.batteryLow
  readonly property string fontUi: values.fontUi
  readonly property string fontMono: values.fontMono
  readonly property int fontSize: values.fontSize
  readonly property int readoutFontSize: values.readoutFontSize
  readonly property int fontWeight: values.fontWeight ?? 700
  readonly property string fontStyle: values.fontStyle ?? "Bold"
  readonly property int radius: values.radius
  readonly property int borderWidth: values.borderWidth
  readonly property bool showDividers: values.showDividers ?? true
  readonly property int barThickness: values.barThickness ?? 22
  readonly property int widgetPadding: values.widgetPadding
  readonly property int tooltipRadius: values.tooltipRadius ?? radius
  readonly property int panelGap: values.panelGap ?? 0
  readonly property int panelWidth: values.panelWidth ?? 360
  readonly property int panelMaxHeight: values.panelMaxHeight ?? 520
  readonly property int panelPadding: values.panelPadding ?? 12
  readonly property int panelSpacing: values.panelSpacing ?? 10
  readonly property int panelRadius: values.panelRadius ?? radius
  readonly property int panelTransitionDuration: values.panelTransitionDuration ?? 140

  property FileView source: FileView {
    path: Quickshell.shellPath("../hyprkarl/current/theme/quickshell.json")
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.load()
  }

  function load(): void {
    values = JSON.parse(source.text())
  }

  Component.onCompleted: load()
}
