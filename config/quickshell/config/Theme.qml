import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property string activeName: ""
  property string activeArtifact: ""
  property var values: ({})
  readonly property bool ready: activeName.length > 0 && Object.keys(values).length > 0

  readonly property var palette: values.palette ?? ({})
  readonly property color foreground: palette.foreground ?? "transparent"
  readonly property color muted: palette.muted ?? "transparent"
  readonly property color accent: palette.accent ?? "transparent"
  readonly property color border: palette.border ?? "transparent"
  readonly property color urgent: palette.urgent ?? "transparent"
  readonly property color warning: palette.warning ?? "transparent"

  readonly property var surfaces: values.surfaces ?? ({})
  readonly property color windowSurface: surfaces.window ?? "transparent"
  readonly property color barSurface: surfaces.bar ?? "transparent"
  readonly property color popupSurface: surfaces.popup ?? "transparent"
  readonly property color tooltipSurface: surfaces.tooltip ?? "transparent"
  readonly property color controlSurface: surfaces.control ?? "transparent"

  readonly property var typography: values.typography ?? ({})
  readonly property string uiFontFamily: typography.uiFamily ?? ""
  readonly property string monoFontFamily: typography.monoFamily ?? ""
  readonly property int bodyFontSize: typography.bodySize ?? 0
  readonly property int readoutFontSize: typography.readoutSize ?? 0
  readonly property int fontWeight: typography.weight ?? 700
  readonly property string fontStyle: typography.style ?? "Bold"

  readonly property var metrics: values.metrics ?? ({})
  readonly property int controlRadius: metrics.radius ?? 0
  readonly property int borderWidth: metrics.borderWidth ?? 0
  readonly property int controlPadding: metrics.controlPadding ?? 0

  readonly property var bar: values.bar ?? ({})
  readonly property int barMinThickness: bar.minimumThickness ?? 0
  readonly property bool showDividers: bar.showDividers ?? true
  readonly property var horizontalWidgetPadding: bar.widgetPadding ?? ({})
  readonly property int widgetMainPadding: horizontalWidgetPadding.main ?? 0
  readonly property int widgetCrossPadding: horizontalWidgetPadding.cross ?? 0
  readonly property int trayMainPaddingOffset: bar.trayPaddingOffset ?? 0
  readonly property var barMargin: bar.margin ?? ({})
  readonly property int barMarginScreen: barMargin.screen ?? 0
  readonly property int barMarginOuter: barMargin.outer ?? 0
  readonly property int barMarginContent: barMargin.content ?? 0

  readonly property var island: bar.island ?? ({})
  readonly property int islandRadius: island.radius ?? controlRadius
  readonly property int cornerCurveSize: island.curveSize ?? 0
  readonly property int cornerCurveRadius: island.curveRadius ?? 0
  readonly property var islandCorners: island.corners ?? ({})
  readonly property var islandBorders: island.borders ?? ({})

  readonly property var panel: values.panel ?? ({})
  readonly property int panelGap: panel.gap ?? 0
  readonly property int panelWidth: panel.width ?? 0
  readonly property int powerPanelWidth: panel.powerWidth ?? panelWidth
  readonly property int panelPadding: panel.padding ?? 0
  readonly property int panelSpacing: panel.spacing ?? 0
  readonly property int panelRadius: panel.radius ?? controlRadius
  readonly property int panelTransitionDuration: panel.transitionDuration ?? 0

  readonly property var tooltip: values.tooltip ?? ({})
  readonly property int tooltipRadius: tooltip.radius ?? controlRadius

  readonly property var menu: values.menu ?? ({})
  readonly property color menuBackground: menu.background ?? popupSurface
  readonly property color menuForeground: menu.foreground ?? foreground
  readonly property color menuAccent: menu.accent ?? accent
  readonly property color menuBorder: menu.border ?? border
  readonly property color menuScrim: menu.scrim ?? "transparent"
  readonly property string menuFont: menu.font ?? uiFontFamily
  readonly property int menuFontSize: menu.fontSize ?? bodyFontSize
  readonly property int menuFontWeight: menu.fontWeight ?? fontWeight
  readonly property int menuWidth: menu.width ?? 0
  readonly property int menuSearchWidth: menu.searchWidth ?? 0
  readonly property int menuReferenceWidth: menu.referenceWidth ?? 0
  readonly property int menuSearchRows: menu.searchRows ?? 0
  readonly property int menuOuterRadius: menu.outerRadius ?? panelRadius
  readonly property int menuInnerRadius: menu.innerRadius ?? controlRadius
  readonly property int menuEntryRadius: menu.entryRadius ?? controlRadius
  readonly property int menuOuterBorderWidth: menu.outerBorderWidth ?? 0
  readonly property int menuOuterPadding: menu.outerPadding ?? 0
  readonly property int menuInnerBorderWidth: menu.innerBorderWidth ?? 0
  readonly property int menuHeaderPadding: menu.headerPadding ?? 0
  readonly property int menuEntryMargin: menu.entryMargin ?? 0
  readonly property int menuEntryPadding: menu.entryPadding ?? 0
  readonly property int menuSelectionBorderWidth: menu.selectionBorderWidth ?? 0
  readonly property real menuHeaderAccentOpacity: menu.headerAccentOpacity ?? 0
  readonly property real menuSelectionAccentOpacity: menu.selectionAccentOpacity ?? 0

  readonly property string stateHome: (Quickshell.env("XDG_STATE_HOME")
    ?? Quickshell.env("HOME") + "/.local/state") + "/hyprkarl"

  property FileView selector: FileView {
    path: root.stateHome + "/current/theme.json"
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.selectTheme()
  }

  property FileView source: FileView {
    path: root.activeArtifact.length === 0
      ? ""
      : root.stateHome + "/themes/" + root.activeArtifact + "/quickshell.json"
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.load()
  }

  function selectTheme(): void {
    const selection = JSON.parse(selector.text())
    activeName = selection.name
    activeArtifact = selection.artifact
  }

  function load(): void {
    values = JSON.parse(source.text())
  }

  Component.onCompleted: selectTheme()
}
