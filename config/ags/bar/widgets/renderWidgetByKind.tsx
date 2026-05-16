import { type WidgetRenderArgs, widgetCatalog } from "./catalog.ts"
import type {
  ResolvedBarWidgetDefinition,
  WidgetKind,
} from "./widgetTypes.ts"

export function renderWidgetByKind(args: WidgetRenderArgs<ResolvedBarWidgetDefinition>) {
  const kind = args.config.kind as WidgetKind
  return widgetCatalog[kind].render(args as never)
}
