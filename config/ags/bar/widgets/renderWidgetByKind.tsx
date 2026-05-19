import {
  type ResolvedBarWidgetDefinition,
  type WidgetKind,
  type WidgetRenderArgs,
  widgetCatalog,
} from "./catalog.ts"

export function renderWidgetByKind(args: WidgetRenderArgs<ResolvedBarWidgetDefinition>) {
  const kind = args.config.kind as WidgetKind
  return widgetCatalog[kind].render(args as never)
}
