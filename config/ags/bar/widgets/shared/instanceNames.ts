export function createWidgetFlyoutName(
  baseName: string,
  widgetId: string,
  monitorConnector?: string | null,
) {
  return `${baseName}-${widgetId}-${monitorConnector ?? "monitor"}`
}
