import { type NormalizedBarWidgetDefinition } from "../configuration.ts"
import { type WidgetRenderArgs, widgetManifests } from "./shared/widgetManifest.tsx"

export function renderBarWidget(args: WidgetRenderArgs<NormalizedBarWidgetDefinition>) {
  return widgetManifests[args.config.kind].render(args as never)
}
