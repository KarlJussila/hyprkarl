import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property string activeName: ""
  property var values: ({})
  readonly property bool ready: activeName.length > 0 && Object.keys(values).length > 0

  readonly property color text: values.text ?? "transparent"
  readonly property color surface: values.surface ?? "transparent"
  readonly property color background: values.background ?? "transparent"
  readonly property color accent: values.accent ?? "transparent"
  readonly property color border: values.border ?? "transparent"
  readonly property color error: values.error ?? "transparent"
  readonly property color batteryLow: values.batteryLow ?? "transparent"
  readonly property string fontUi: values.fontUi ?? ""
  readonly property string fontMono: values.fontMono ?? ""
  readonly property int fontSize: values.fontSize ?? 0
  readonly property int readoutFontSize: values.readoutFontSize ?? 0
  readonly property int fontWeight: values.fontWeight ?? 700
  readonly property string fontStyle: values.fontStyle ?? "Bold"
  readonly property int radius: values.radius ?? 0
  readonly property int islandRadius: values.islandRadius ?? radius
  readonly property int cornerCurveSize: values.cornerCurveSize ?? 0
  readonly property int cornerCurveRadius: values.cornerCurveRadius ?? 0
  readonly property var islandCorners: values.islandCorners ?? ({
    "screenOuter": "round",
    "screenInner": "round",
    "contentOuter": "round",
    "contentInner": "round"
  })
  readonly property var islandBorders: values.islandBorders ?? ({
    "screen": true,
    "content": true,
    "outer": true,
    "inner": true
  })
  readonly property var barMargin: values.barMargin ?? ({})
  readonly property int barMarginScreen: barMargin.screen ?? 0
  readonly property int barMarginOuter: barMargin.outer ?? 0
  readonly property int barMarginContent: barMargin.content ?? 0
  readonly property int borderWidth: values.borderWidth ?? 0
  readonly property bool showDividers: values.showDividers ?? true
  readonly property int barMinThickness: values.barMinThickness ?? 22
  readonly property var horizontalWidgetPadding: values.horizontalWidgetPadding ?? ({})
  readonly property int widgetMainPadding: horizontalWidgetPadding.main ?? 0
  readonly property int widgetCrossPadding: horizontalWidgetPadding.cross ?? 0
  readonly property int trayMainPaddingOffset: values.trayMainPaddingOffset ?? 0
  readonly property int controlPadding: values.controlPadding ?? 0
  readonly property int tooltipRadius: values.tooltipRadius ?? radius
  readonly property int panelGap: values.panelGap ?? 0
  readonly property int panelWidth: values.panelWidth ?? 360
  readonly property int powerPanelWidth: values.powerPanelWidth ?? panelWidth
  readonly property int panelPadding: values.panelPadding ?? 12
  readonly property int panelSpacing: values.panelSpacing ?? 10
  readonly property int panelRadius: values.panelRadius ?? radius
  readonly property int panelTransitionDuration: values.panelTransitionDuration ?? 140
  readonly property var menu: values.menu ?? ({})
  readonly property color menuBackground: menu.background ?? surface
  readonly property color menuForeground: menu.foreground ?? text
  readonly property color menuAccent: menu.accent ?? accent
  readonly property color menuBorder: menu.border ?? border
  readonly property color menuScrim: menu.scrim ?? "transparent"
  readonly property string menuFont: menu.font ?? fontUi
  readonly property int menuFontSize: menu.fontSize ?? fontSize
  readonly property int menuFontWeight: menu.fontWeight ?? fontWeight
  readonly property int menuWidth: menu.width ?? 280
  readonly property int menuSearchWidth: menu.searchWidth ?? 560
  readonly property int menuReferenceWidth: menu.referenceWidth ?? 800
  readonly property int menuSearchRows: menu.searchRows ?? 10
  readonly property int menuOuterRadius: menu.outerRadius ?? panelRadius
  readonly property int menuInnerRadius: menu.innerRadius ?? radius
  readonly property int menuEntryRadius: menu.entryRadius ?? radius
  readonly property int menuOuterBorderWidth: menu.outerBorderWidth ?? 3
  readonly property int menuOuterPadding: menu.outerPadding ?? 6
  readonly property int menuInnerBorderWidth: menu.innerBorderWidth ?? 3
  readonly property int menuHeaderPadding: menu.headerPadding ?? 4
  readonly property int menuEntryMargin: menu.entryMargin ?? 4
  readonly property int menuEntryPadding: menu.entryPadding ?? 8
  readonly property int menuSelectionBorderWidth: menu.selectionBorderWidth ?? 2
  readonly property real menuHeaderAccentOpacity: menu.headerAccentOpacity ?? 0.3
  readonly property real menuSelectionAccentOpacity: menu.selectionAccentOpacity ?? 0.16

  property FileView selector: FileView {
    path: Quickshell.shellPath("../hyprkarl/current/theme.name")
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.selectTheme()
  }

  property FileView source: FileView {
    path: root.activeName.length === 0
      ? ""
      : Quickshell.shellPath("../../themes/" + root.activeName + "/quickshell.json")
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.load()
  }

  function selectTheme(): void {
    activeName = selector.text().trim()
  }

  function load(): void {
    values = JSON.parse(source.text())
  }

  Component.onCompleted: selectTheme()
}
