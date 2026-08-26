import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property string activeName: ""
  property string activeArtifact: ""
  property var values: ({})
  readonly property var document: values
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
  readonly property color notificationSurface: surfaces.notification ?? popupSurface
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

  readonly property var switchAppearance: values["switch"] ?? ({})

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
  readonly property color panelBackground: panel.background ?? popupSurface
  readonly property color panelSectionBackground:
    panel.sectionBackground ?? panelBorder
  readonly property color panelForeground: panel.foreground ?? foreground
  readonly property color panelAccent: panel.accent ?? accent
  readonly property color panelBorder: panel.border ?? border
  readonly property string panelFont: panel.font ?? uiFontFamily
  readonly property int panelFontSize: panel.fontSize ?? bodyFontSize
  readonly property int panelFontWeight: panel.fontWeight ?? fontWeight
  readonly property int panelOuterRadius: panel.outerRadius ?? controlRadius
  readonly property int panelInnerRadius: panel.innerRadius ?? controlRadius
  readonly property int panelEntryRadius: panel.entryRadius ?? controlRadius
  readonly property int panelOuterBorderWidth: panel.outerBorderWidth ?? borderWidth
  readonly property int panelOuterPadding: panel.outerPadding ?? 0
  readonly property int panelInnerBorderWidth: panel.innerBorderWidth ?? borderWidth
  readonly property int panelHeaderPadding: panel.headerPadding ?? controlPadding
  readonly property int panelEntryPadding: panel.entryPadding ?? controlPadding
  readonly property int panelSelectionBorderWidth: panel.selectionBorderWidth ?? 0
  readonly property real panelHeaderAccentOpacity: panel.headerAccentOpacity ?? 0
  readonly property real panelSelectionAccentOpacity: panel.selectionAccentOpacity ?? 0
  readonly property int panelRadius: panelOuterRadius
  readonly property int panelTransitionDuration: panel.transitionDuration ?? 0

  readonly property var tooltip: values.tooltip ?? ({})
  readonly property int tooltipRadius: tooltip.radius ?? controlRadius

  readonly property var osd: values.osd ?? ({})
  readonly property int osdWidth: osd.width ?? 300
  readonly property int osdMediaWidth: osd.mediaWidth ?? osdWidth
  readonly property int osdPadding: osd.padding ?? controlPadding
  readonly property int osdSpacing: osd.spacing ?? controlPadding
  readonly property int osdRadius: osd.radius ?? panelRadius
  readonly property int osdIconSize: osd.iconSize ?? 20
  readonly property int osdProgressHeight: osd.progressHeight ?? 6
  readonly property int osdTransitionDuration: osd.transitionDuration
    ?? panelTransitionDuration

  readonly property var notification: values.notification ?? ({})
  readonly property int notificationWidth: notification.width ?? 420
  readonly property int notificationCompactWidth: notification.compactWidth ?? 210
  readonly property int notificationPadding: notification.padding ?? controlPadding
  readonly property int notificationSpacing: notification.spacing ?? controlPadding
  readonly property int notificationStackSpacing: notification.stackSpacing
    ?? notificationSpacing
  readonly property int notificationRadius: notification.radius ?? panelRadius
  readonly property int notificationIconSize: notification.iconSize ?? 32
  readonly property real notificationIndicatorScale: notification.indicatorScale ?? 1.5
  readonly property int notificationProgressHeight: notification.progressHeight ?? 6
  readonly property int notificationTransitionDuration:
    notification.transitionDuration ?? panelTransitionDuration

  readonly property var polkit: values.polkit ?? ({})
  readonly property int polkitWidth: polkit.width ?? 440
  readonly property int polkitPadding: polkit.padding ?? controlPadding
  readonly property int polkitSpacing: polkit.spacing ?? controlPadding
  readonly property int polkitRadius: polkit.radius ?? panelRadius
  readonly property int polkitIconSize: polkit.iconSize ?? 36
  readonly property real polkitHeaderAccentOpacity:
    polkit.headerAccentOpacity ?? 0.3
  readonly property int polkitTransitionDuration:
    polkit.transitionDuration ?? panelTransitionDuration

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

  readonly property var applicationPicker: values.applicationPicker ?? ({})
  readonly property int applicationPickerWidth:
    applicationPicker.width ?? menuSearchWidth
  readonly property int applicationPickerRows: applicationPicker.rows ?? 7
  readonly property int applicationPickerIconSize: applicationPicker.iconSize ?? 32

  readonly property var calculator: values.calculator ?? ({})
  readonly property int calculatorWidth: calculator.width ?? menuSearchWidth
  readonly property int calculatorHistoryRows: calculator.historyRows ?? 5

  readonly property var wallpaperPicker: values.wallpaperPicker ?? ({})
  readonly property int wallpaperPickerColumns: wallpaperPicker.columns ?? 3
  readonly property real wallpaperThumbnailScreenFraction:
    wallpaperPicker.thumbnailScreenFraction ?? 0.25
  readonly property int wallpaperPickerGap:
    wallpaperPicker.gap ?? menuOuterPadding * 2

  readonly property var displayArrangement: values.displayArrangement ?? ({})
  readonly property int displayArrangementWidth:
    displayArrangement.width ?? 960
  readonly property int displayArrangementHeight:
    displayArrangement.height ?? 600
  readonly property real displayArrangementBezelFraction:
    displayArrangement.bezelFraction ?? 0.08

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
